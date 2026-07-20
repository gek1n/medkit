# Elly (MedKit) — Claude Code Context

Flutter app for family medication/health tracking: schedules, doses, family/caregiver
sharing, wellbeing check-ins, doctor visits, medical record ("медкартка"). Privacy-first —
local-first encrypted storage, no forced accounts; optional end-to-end encrypted family
sync and cloud backup are opt-in.

Repo: `C:\Users\user\Desktop\medkit` (this repo). Separate, sibling backend repo:
`C:\Users\user\Desktop\medkit-backend` (PHP, thin anonymous relay — see its own
`DEPLOY.md`, not git-tracked, deployed manually via cPanel; cPanel username `gdtmclhw`,
use it wherever `DEPLOY.md` says `CPANEL_USER`).

## ⚠️ Live in production — active users, backward compatibility required

Elly is published in the App Store with real, active users (initial distribution:
Ukraine only). This changes the ground rules from earlier development: **any change
that touches data already stored on real devices/servers, a sync/API contract, or
already-scheduled notifications must be backward-compatible** — it must not break,
silently corrupt, or lose data/functionality for someone already running an
older-or-current version. App stores don't force-update everyone instantly, so
old and new versions run concurrently in the wild for a while after every release.
Concretely:

- **DB schema changes**: every migration must correctly transform *existing* rows,
  not just define the new shape for fresh installs — reason about the
  `if (from < N) { ... }` block against realistic old data, not just a clean
  `flutter run` on an empty simulator/fresh install.
- **Sync/API contract changes** (`medkit-backend` relay, `SubscriptionApiClient`,
  `AccountService`, family sync): the backend must keep serving whatever
  request/response shape *older still-installed* client versions send, until you're
  confident nobody is running that old version anymore. Don't rename/remove a field
  or endpoint outright — add a new one and deprecate gradually, or keep the old one
  working alongside it.
- **Notification ID scheme / scheduling logic changes**: changing the
  `xNotificationId(id)` offset convention or the `IntakeGenerator`/
  `ActivityLogGenerator` dedup logic can orphan or duplicate reminders already
  scheduled on real users' devices right now.
- **Removing/renaming a `context.l10n` key, a provider, or a stored
  SharedPreferences/secure-storage key** that an already-installed build still reads
  — an in-flight update shouldn't crash or silently reset a user's settings because a
  key it expects has vanished.
- **In-App Purchase product IDs** (`plus_monthly`, `plus_yearly`, `family_monthly`,
  `family_yearly`) are now live in App Store Connect — never rename/repurpose one;
  Apple/Google tie a user's entire purchase and renewal history to the exact string.
- When in doubt whether a change is "safe" for existing users, ask explicitly rather
  than assume — this wasn't a live concern earlier in development (no real users
  yet), it is now.

## Brand / design

- **Palette (current, do not confuse with older purple mockups)**: sage green
  primary `#4C9A6A`, warm cream background `#F9EDE1`, peach/orange accent `#E8935A`.
  Defined once in `lib/core/theme/app_colors.dart` — always reference `AppColors.*`,
  never a literal hex (the app has previously had leftover hardcoded purple hexes
  that didn't follow theme changes — check for this class of bug if colors look wrong
  after a rebrand).
- **Font**: Nunito everywhere, via `GoogleFonts.nunito*` in `app_text_styles.dart` /
  `app_theme.dart` — only these two files control it project-wide.
- **Icons**: real `Icon(Icons.xxx_rounded)` widgets, not emoji, for decorative/status
  UI chrome. Emoji are kept only where they're actual user-facing *content*: avatar
  pickers, mood-rating pickers, and OS notification title/body text (native
  notification tray doesn't render Flutter icons). Shared icon mapping helpers:
  `lib/core/utils/med_form_icons.dart` (medication form → icon) — don't recreate a
  local per-file switch statement for this, several used to exist and were
  consolidated.
- `withOpacity()` is deprecated — always use `.withValues(alpha: x)`.

## Repo layout

```
lib/
  core/
    theme/       AppColors, AppTextStyles, AppDimensions, AppTheme
    utils/       l10n_ext.dart (context.l10n), date_utils.dart, med_form_icons.dart, ...
    providers/   Riverpod providers (plan_provider, app_language_provider, notification_settings_provider, ...)
    services/    cross-cutting services — NotificationService, DbEncryptionService,
                 sync/family-sync/backup services, AI/voice/scan services, generators
  data/
    db/          Drift schema (app_database.dart, tables/, migrations inline)
    repositories/ one repository class per table/table-group, exposed via Provider
    models/      plain data models used outside Drift row types
  features/      one directory per screen area: today, schedule, medcard, medications,
                 family, profile, appointments, wellbeing, onboarding, voice, scan,
                 backup, plans, notifications, legal, help, lock, export, add, placeholder
  shared/widgets/  reusable Mk*-prefixed components (MkCard, MkButton, MkFormHeader,
                 MkSaveButton, MkListWidgets, etc.) — check here before writing a new
                 one-off form/list/header widget, most patterns already exist
  l10n/          app_uk.arb (template/source of truth), app_en.arb, app_ru.arb,
                 generated app_localizations*.dart (never hand-edit generated files)
  main.dart      MedKitApp (MaterialApp + locale wiring) + _Shell (bottom-nav root)
packages/
  medkit_db_key_storage/  local, first-party Flutter plugin — direct native
                 Keychain (iOS) / EncryptedSharedPreferences+Keystore (Android)
                 storage for exactly one value, the DB encryption key. See
                 "Data layer" below for why this exists instead of
                 flutter_secure_storage.
docs/            marketing brief, screens doc, legal doc drafts, l10n_glossary.md,
                 multifamily_billing_plan.md
test/            narrow unit tests for crypto/sync services — no widget test coverage
                 yet for screens or the notification-scheduling logic (a real gap,
                 see "Known gaps" below)
```

## Architecture rules

### Data layer (Drift + SQLCipher)
- Local DB is SQLCipher-encrypted (`lib/core/services/db_encryption_service.dart`
  manages the key, `app_database.dart` wires it into Drift's
  `NativeDatabase.createInBackground`).
- **DB encryption key storage**: as of the native-storage migration, the key lives in
  `packages/medkit_db_key_storage` — a local, first-party Flutter plugin that calls
  Keychain (iOS)/Keystore (Android) directly, with ONE fixed, never-varying set of
  storage attributes. This replaced `flutter_secure_storage` for this specific key
  after three separate production incidents traced to that package's own documented
  Keychain-accessibility/duplicate-item bugs (GitHub issues #960, #573, #762 on
  `juliansteenbakker/flutter_secure_storage`) — see git history around July 2026 for
  the full investigation. `flutter_secure_storage` is still used for everything else
  (`AccountService`, `FileEncryptionService`, `SharedChannelKeyStorage`,
  `BackupSettingsService`) — only the DB key moved, since it was the one causing
  repeated "database error" reports for real users.
  - `DbEncryptionService._getOrCreateKey()` reads the new native store first; if
    empty (device hasn't migrated yet), falls back to the legacy
    `flutter_secure_storage` location, migrates it into the new store, and keeps the
    old copy untouched as a fallback (never deletes it automatically — only
    `resetCorruptedDatabase()` clears both explicitly).
  - `BackupCryptoService.wrapKeys()`/`unwrapAndInstallKeys()` handle the DB key
    explicitly via `DbEncryptionService.currentKeyForBackup()` — it does **not** come
    through the generic `flutter_secure_storage.readAll()` sweep, because the native
    store isn't part of that package and readAll() can't see it. If you ever touch
    the backup envelope format, make sure this explicit key stays wired — it's easy
    to assume readAll() is "getting everything" and silently drop it again (that was
    the actual, previously-undetected bug: the DB key was never actually included in
    cloud backups on iOS due to a Keychain accessibility mismatch).
  - **iOS side needs Mac-side verification** — see "Build & release" below,
    "Post-migration Mac checklist".
- New table → add to `data/db/tables/`, register in `app_database.dart`'s
  `@DriftDatabase(tables: [...])` list, bump `schemaVersion`, add a
  `if (from < N) { ... }` migration block, then run
  `dart run build_runner build --delete-conflicting-outputs` to regenerate
  `app_database.g.dart`. **The migration block is not optional/theoretical
  anymore — see "Live in production" above, it runs against real users' real data.**
- New repository → wraps a table (or a few related ones), exposed as
  `final xRepositoryProvider = Provider<XRepository>((ref) => XRepository(ref.watch(databaseProvider), ref));`.
- **Any mutating repository method that changes data feeding a background-scheduled
  notification must itself cancel/update the corresponding `NotificationService`
  entry.** Don't assume a screen-level "regenerate today's list" pass will clean up
  stale ones — see the Notifications section below, this exact gap caused a real
  duplicate-reminder bug.
- **Any mutating method whose data participates in sync (account-sync or
  family-sync) must set `updatedAt: Value(DateTime.now())`.** Historically only
  `insert` set this (via `withDefault`) and every `update`/`markX`/`softDelete`
  method silently omitted it, which meant sync's "what changed" detection missed
  every edit to existing rows. Double-check new mutating methods set it.

### Notifications (`lib/core/services/notification_service.dart`)
- Single point of scheduling all local notifications (`flutter_local_notifications`).
  Stable numeric ID scheme per entity type+kind (see the `xNotificationId(id)`
  helper functions in the file for the offset convention).
- **Golden rule: any time you change *when* something is scheduled, cancel the old
  notification before scheduling the new one.** Never rely solely on
  "regenerate + dedupe by exact match" — `IntakeGenerator`/`ActivityLogGenerator`
  dedupe today/tomorrow rows by exact `(id, scheduledAt)`, so editing a time creates
  a *second* row/notification next to the stale one unless the repository's
  `update()` explicitly purges still-pending future rows first (see
  `MedicationsRepository._cancelFutureStaleIntakes` /
  `ActivitiesRepository._cancelFutureStaleLogs` for the established pattern to copy
  for any new schedulable entity type).
- `NotificationService` has **no `BuildContext`** (it can run from background/cold
  start) — it cannot use `context.l10n`. Localized notification text goes through
  `lookupAppLocalizations(Locale)` (a function generated by `flutter gen-l10n`),
  fed by `AppLanguageNotifier.loadLanguageId()` (reads the saved language pref
  straight from `SharedPreferences`, no Riverpod `ref` needed). Follow this pattern
  for any other background/no-context code that needs localized strings.
- Settings changes (push toggle, quiet hours, per-member mute) must retroactively
  cancel/reschedule *already-created* reminders, not just affect future ones — see
  `lib/core/services/notification_resync_service.dart` and how
  `NotificationSettingsNotifier` calls it after every relevant setter. This was an
  explicit, firm user requirement (turning off push must silence everything
  immediately, not just "from now on").

### Diagnostics (Firebase Crashlytics)
- Wired in `lib/main.dart` (`FlutterError.onError`, `PlatformDispatcher.instance.onError`,
  the top-level `runZonedGuarded` catch-all, gated on a `_crashReportingReady` bool
  that only flips true if `Firebase.initializeApp()` actually succeeded).
  `AppLogger` is a **no-op in production builds** (see "Build & release" below), so
  before this, every production incident had to be diagnosed blind from a user's
  description — this is the fix for that gap, added after three separate blind
  guesses at the same underlying DB-key bug this month.
- A non-fatal report is recorded at the exact point `_DatabaseErrorScreen` is shown
  (`_RootRouter`'s `currentMemberProvider` error branch) — this is the single most
  useful hook in the file for diagnosing any future recurrence, since it's the
  real thrown exception/stack from a real device, not a paraphrase. A custom key
  (`db_key_mismatch_streak`) is also set from `recordKeyMismatchOccurrence()` so the
  dashboard can distinguish "happened once" from "still happening after relaunch".
- No PII goes into any Crashlytics call (no names/medications/symptoms) — same
  privacy stance as `AppLogger`.
- Android needs the Crashlytics Gradle plugin applied (`android/settings.gradle.kts`
  + `android/app/build.gradle.kts`, same file-exists-gated pattern as
  `google-services.json`) — already done, don't remove it when touching those files.

### Screens / widgets
- Feature-per-directory under `lib/features/<feature>/`. Cross-feature reusable
  widgets go in `lib/shared/widgets/` with `Mk`-prefixed names.
- API keys (Claude, OpenAI, etc.) live server-side only, in `medkit-backend` — never
  embedded in the Flutter client.

## i18n / translation rules (authoritative — read this before touching any UI string)

- **Every user-visible string goes through `context.l10n.keyName`** — the extension
  in `lib/core/utils/l10n_ext.dart` exposes the generated `AppLocalizations`.
- **`lib/l10n/app_uk.arb` (Ukrainian) is the template/source of truth**, not
  English — author new keys there first, in Ukrainian.
- **After any edit to `app_uk.arb`, immediately run `flutter gen-l10n`** before
  referencing the new key from Dart source, or you'll get "undefined_getter" compile
  errors.
- Full parallel translations are maintained per locale: `app_en.arb`, `app_ru.arb`
  (more may be added later). They must stay in **exact 1:1 key parity** with
  `app_uk.arb` — same keys, same order, and every `@key` placeholder-metadata block
  byte-identical across locales (only the human-facing value strings differ).
  Verify parity with a small Node script whenever ARB files change — there is no
  `python3` in this environment (only a Windows-Store stub), use
  `node -e "..."` instead. Example check:
  ```js
  const fs = require('fs');
  const uk = JSON.parse(fs.readFileSync('lib/l10n/app_uk.arb', 'utf8'));
  const xx = JSON.parse(fs.readFileSync('lib/l10n/app_xx.arb', 'utf8'));
  const a = new Set(Object.keys(uk)), b = new Set(Object.keys(xx));
  console.log('missing:', [...a].filter(k => !b.has(k)));
  console.log('extra:', [...b].filter(k => !a.has(k)));
  ```
- **ICU plurals**: the Ukrainian source deliberately uses 3 forms (`one`/`few`/
  `other`), omitting the 4th CLDR "many" category — `flutter gen-l10n` falls back to
  `other` for any missing category, confirmed working. English collapses to 2 forms
  (`one`/`other`, since English has no "few"). Russian keeps 3 forms mapped to its
  own CLDR rule (get the noun case right per bucket — a frequent source of
  mistranslation, e.g. "день/дня/дней"). When adding a new plural key, search the uk
  ARB for `plural,` to see the existing pattern.
- Interpolated strings use named `{placeholder}` tokens with a matching
  `"@key": {"placeholders": {"name": {"type": "String"|"int"}}}` block — never
  rename or drop a placeholder when translating, only reorder surrounding words for
  target-language grammar.
- **Strings living in code without a `BuildContext`** (free top-level functions,
  extension getters/methods without a context param, `static const` default
  constructor parameter values, `const` lists/maps built outside `build()`) need
  `BuildContext` threaded through as an explicit parameter (or converted from
  `const` to a context-taking function/getter). Before changing such a
  function/widget's signature, **grep the whole `lib/` tree for every call site**,
  not just the file you're editing — these are often shared across many features.
- `docs/l10n_glossary.md` is a living glossary of Ukrainian-source terms that are
  genuine homonyms or abbreviations and easy to mistranslate (e.g. "Прийом" means
  "medication dose" in some keys and "doctor's appointment" in others depending on
  context; "Зріз" means "wellbeing check-in", not literally "a slice"; "Курс" always
  means "medication treatment course"). Consult it before translating a batch of new
  strings, and add a new entry whenever you spot another ambiguous term — translator
  notes go in this glossary file, **not** as inline ARB comments (ARB stays clean by
  convention; JSON doesn't support comments anyway).
- **After adding a newly-supported language**, also update two hardcoded allowlists
  that don't auto-detect from which ARB files exist on disk:
  - `lib/main.dart` — `supportedLocales` list and the
    `const [...].contains(languageCode)` fallback-to-Ukrainian check.
  - `lib/core/services/notification_service.dart` — `_l10n()`'s own locale
    allowlist (background notifications resolve locale independently of the
    widget tree).
- `lib/core/providers/app_language_provider.dart` (`appLanguageProvider`) is the
  single source of truth for the user's language choice — it drives **both** the UI
  locale (via `MaterialApp.locale` in `main.dart`) **and** voice/dictation locale
  (`speech_to_text`). Picked in Профіль → Мова. Auto-detects device locale on first
  install, falls back to English if the device locale isn't supported.
- **Verification checklist** after any batch of string extraction/translation work:
  `flutter gen-l10n` (expect 0 untranslated messages), `flutter analyze` (clean),
  and a Grep for `[а-яіїєА-ЯІЇЄ]` across the changed files/directories — remaining
  matches should be **only** `//`/`///` code comments, zero live UI strings. When
  delegating extraction/translation work to a subagent for scale, always
  independently re-run this verification yourself rather than trusting its
  self-reported summary — subagents have been caught making arithmetic/count errors
  in their own reports.
- Business-content restriction (separate from UI-language support, do not confuse
  the two): affiliate/monetization content (pharmacy partner links, prices) should
  stick to the app's actual commercial partners and currencies as configured in
  `AffiliateConfigService` — check current config before assuming any specific
  country/vendor list, it's fetched remotely rather than hardcoded now.

## Feature-creation checklist

0. Does this change touch data/contracts already live for real users (DB rows, sync
   API shape, notification IDs, stored preference keys, IAP product IDs)? Read
   "Live in production — active users" at the top of this file first.
1. New schedulable entity (has its own reminder notification)? Follow the
   Notifications section above exactly — cancel-before-reschedule on every time
   edit, retroactive resync on relevant settings changes, locale via
   `lookupAppLocalizations` if the code path has no `BuildContext`.
2. New DB table/column? Migration + `build_runner`, `updatedAt` on every mutator if
   it should participate in sync — the migration must handle existing installs'
   real data, not just fresh installs.
3. New screen/dialog/snackbar text? Extract through `context.l10n` from the start —
   don't hardcode Ukrainian "temporarily", it always needs doing eventually and is
   cheaper to do inline while the strings are fresh in context.
4. Reusable UI pattern? Check `lib/shared/widgets/` first.
5. Before wiring anything to a remote service (Google Drive, Firebase, relay
   backend), check whether it needs one-time manual cloud-console setup (OAuth
   client, API enablement, service account) — several past features shipped code
   that then needed a manual console step the AI cannot perform (see "Known
   external dependencies" below).

## Collaboration / working-style notes

- **Never commit/push/create-PR/merge without a fresh, explicit instruction in the
  current conversation.** A prior approval for one commit does not imply standing
  authorization for later ones, even in the same session.
- Don't re-verify every small edit by launching an emulator/simulator — the user
  does manual visual QA themselves. Get the touched code compiling clean
  (`flutter analyze`) and stop there; reserve full click-through verification for
  when something is suspected actually broken or the user explicitly asks for it.
- For large mechanical work across many files (e.g. i18n extraction across dozens
  of screens), delegating well-scoped chunks to subagents with very explicit
  conventions in the prompt is fine and efficient — but **always independently
  re-verify their results** yourself (`flutter analyze`, re-run key-parity/grep
  checks, spot-check a handful of actual values) rather than trusting the returned
  summary at face value.
- This repo has accumulated stale `.claude/worktrees/*` directories from past
  sessions sitting at old commits. If a worktree's `flutter analyze`/screen output
  looks suspiciously outdated, check `git log`/`git status` against the current
  branch tip before assuming it's current — don't just trust the worktree you were
  dropped into. (As of this writing, `origin/master` on GitHub *is* kept in sync via
  normal PR merges — this is no longer the stale-vs-local-master situation from
  earlier project history.)
- **When the user asks you to build a release (`flutter build ipa`/`apk`/
  `appbundle`), ALWAYS ask first whether they want a test/QA build or a real
  production (App Store/Google Play submission) build before running
  anything.** Never assume — the two use different `--dart-define` flags (see
  "Build & release" below) and getting it backwards either ships test billing
  into a store submission or produces a TestFlight build that can't actually
  complete a purchase. See `docs/multifamily_billing_plan.md` for the full
  billing/multi-family design reasoning.

## Build & release — test vs production

### ⚠️ Post-migration Mac checklist (do this before the next real build)

`packages/medkit_db_key_storage` (see "Data layer" above) was built and verified
from a Windows machine, which cannot run CocoaPods/Xcode. Android was fully
build-verified (`flutter build apk --debug` succeeded, plugin compiled and linked
into a real APK, auto-registered in `GeneratedPluginRegistrant.java`). **iOS side
registration goes through CocoaPods (`pod install`), which was never actually run**
— `ios/Runner/GeneratedPluginRegistrant.{h,m}` are gitignored/build-generated and
don't exist yet in this checkout. Before shipping:

1. `cd ios && pod install` (or just `flutter build ipa`/`flutter run -d <device>`,
   which triggers it automatically) — confirm it resolves
   `packages/medkit_db_key_storage/ios/medkit_db_key_storage.podspec` cleanly and
   that `MedkitDbKeyStoragePlugin` shows up in the generated
   `GeneratedPluginRegistrant.m`. If pod install fails on this podspec, the
   attribute names/structure were copied from `flutter_secure_storage`'s own
   working podspec as a reference — compare against
   `~/.pub-cache/hosted/pub.dev/flutter_secure_storage-*/ios/` if something looks
   off.
2. **Run on a real iOS device (not just Simulator)** — Keychain accessibility
   semantics (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) that this whole
   fix hinges on don't meaningfully exercise on Simulator. Test, in this rough
   order of importance:
   - Fresh install → onboarding → force-quit → reopen (baseline).
   - Force-quit → wait several hours/overnight → reopen (the specific case that was
     still broken after the previous `flutter_secure_storage`-side fix — this is
     the one that actually justified this whole migration).
   - **Restore from iCloud/Google Drive backup** (fresh install or existing data,
     either) — this is the highest-stakes untested path: the previously-undetected
     bug was that the DB key likely was never actually included in cloud backups
     at all (`BackupCryptoService.wrapKeys()`'s `readAll()` couldn't see a key
     stored under `first_unlock_this_device` accessibility). Confirm the restored
     app actually opens, not just that "restore" reports success.
   - If you have (or can get) a device that still has the *previous* app version
     installed with real data: update it to this build and confirm the one-time
     legacy-key migration in `DbEncryptionService._getOrCreateKey()` works —
     without this, existing users lose access on update.
3. Watch the Firebase Crashlytics console during all of the above — any
   `DbKeyUnavailableException`/`DbTemporarilyLockedException`/native
   `keychain_locked`/`write_failed`/`read_failed` error means something in the
   native Swift (`packages/medkit_db_key_storage/ios/Classes/MedkitDbKeyStoragePlugin.swift`)
   needs a fix, not another workaround layered on top — reason from the actual
   OSStatus in the error `details`.

The app builds (`flutter analyze` clean, Android APK builds) — what's unverified is
specifically the iOS native Keychain code path end-to-end on real hardware.

### Test vs production build flag

The app ships from ONE codebase in two distinct build configurations, switched
by a single compile-time flag — never a runtime toggle, so an installed app
can never flip itself between modes and a build that forgets the flag
defaults to the safe (production) behavior.

- **`lib/core/config/app_env.dart`** — `AppEnv.isTestBuild`, backed by
  `bool.fromEnvironment('APP_TEST_BUILD', defaultValue: false)`.
- What it gates:
  - **Billing** (`SubscriptionService.purchase()`/`cancelOrManageSubscription()`
    in `subscription_service.dart`): test build → calls the server's
    `verify-test`/`cancel-test` endpoints (no real App Store/Google Play
    charge, requires `BILLING_TEST_SECRET` to match the backend's `.env`).
    Production build → real `buy()` (StoreKit2/Play Billing) and, for
    cancelling, opens native subscription management
    (`apps.apple.com/account/subscriptions` / Play Store subscriptions) since
    apps cannot cancel real subscriptions via API.
  - **Logging** (`AppLogger` in `app_logger.dart`): production build is a
    total no-op — no file writes, no `debugPrint`, `readAll()` returns empty.
    Test build logs and persists to `app_log.txt` as before. (Notification
    titles contain real people's names, e.g. "Кохана · Час прийняти ліки" —
    that's why this is gated, not just a performance nicety.)
  - **Debug log viewer** (`_HiddenDebugLogTrigger` in `profile_screen.dart`,
    the 7-taps-on-"Elly" easter egg): no-op in production, opens
    `DebugLogScreen` in test builds.

### Commands

```bash
# Test / QA build (TestFlight, internal APK for the team)
flutter run --dart-define=APP_TEST_BUILD=true --dart-define=BILLING_TEST_SECRET=<value>
flutter build ipa --release --dart-define=APP_TEST_BUILD=true --dart-define=BILLING_TEST_SECRET=<value>
flutter build apk --release --dart-define=APP_TEST_BUILD=true --dart-define=BILLING_TEST_SECRET=<value>

# Production build for App Store / Google Play — omit BOTH flags entirely
flutter build ipa --release
flutter build appbundle --release
```

The actual `BILLING_TEST_SECRET` value lives in `local.secrets.md` at the repo
root (gitignored, never commit it) — **not** in this file. It must match
`BILLING_TEST_SECRET` in `medkit_private/.env` on the backend host. Current
value there is weak (sequential digits) and flagged for rotation — check
`local.secrets.md` for status before assuming it's still valid.

### Backend `.env` requirements for real (production) billing to actually work

Setting the client flags above is necessary but not sufficient — the
server's real `/subscription/verify` endpoint independently needs Apple/Google
credentials configured in `medkit_private/.env`, or it throws a clear
"not configured" error. As of this writing these are **not yet set**:
- `APPLE_ISSUER_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY_PATH` (App Store
  Server API — modern approach, no legacy shared secret). A candidate key
  file (`apple-subscription-key.p8`) already exists in the `medkit-backend`
  repo root and needs uploading to the host + its Issuer ID/Key ID pulled
  from App Store Connect → Users and Access → Integrations. Don't confuse it
  with `AuthKey_96P6VWLJX9.p8` in the same directory, which is a different
  key (Sign in with Apple/APNs, not subscriptions).
- `GOOGLE_PLAY_SERVICE_ACCOUNT_PATH`, `GOOGLE_PLAY_PACKAGE_NAME` — no service
  account JSON exists yet anywhere in the repo; needs creating fresh in
  Google Cloud Console (separate, least-privilege from the existing FCM
  service account — "View financial data" role in Play Console).
- `BILLING_TEST_MODE` can safely stay `true` permanently now that the client
  gates which endpoint it calls at compile time — the old advice to toggle it
  off before every store submission is no longer the primary defense (though
  still a reasonable extra layer if the test secret ever leaks).

## Known external dependencies needing manual (non-code) setup

These fail predictably with a clear error until someone with console access
performs a one-time step — recognize this class of issue quickly rather than
treating it as a code bug:
- **Google Drive backup 403 "API not used/disabled"**: the Drive API must be
  enabled for the app's own GCP project (`elly-18aa1` / `964528755773`) at
  `console.developers.google.com/apis/api/drive.googleapis.com/overview?project=964528755773`
  — one-time, self-service, the exact URL is in the error message itself.
- **iCloud backup**: needs the iCloud capability enabled in Xcode (Signing &
  Capabilities) with container `iCloud.com.ellyapp.medkit`, requires an Apple
  Developer account.
- **Google/Apple Sign-In**: needs a real Web Client ID from Google Cloud Console
  (currently referenced via config, verify it's not a placeholder before debugging
  sign-in failures as a code issue) and, for Apple, the "Sign In with Apple"
  capability in Xcode. Apple Sign-In only works "out of the box" on iOS/macOS —
  Android needs a separate web-based OAuth flow that is not currently configured.
- **Push notifications (FCM)**: needs `google-services.json` /
  `GoogleService-Info.plist` in place and, on iOS, the "Background Modes → Remote
  notifications" capability in Xcode.

## Known gaps (not yet fixed, worth keeping in mind)

- **No test coverage for the notification-scheduling logic or any screen widget.**
  `test/` only has narrow unit tests for crypto/sync services. Two real regressions
  this project has hit shipped silently because of this (push-toggle not cancelling
  existing reminders; duplicate reminders after editing a schedule time) — both
  fixed, neither has a regression test guarding against recurrence.
- `IntakeGenerator`/`ActivityLogGenerator` are near-duplicate code (same
  generate-per-day-from-schedule-with-cancel-dedup logic, separately implemented) —
  a candidate for consolidation into one generic generator.
- `FamilyGroupService.refreshPeers` polls `RelayApiClient.fetchState` repeatedly
  (every 15-30s in observed logs) for channels that return "no state yet" and never
  seems to give up or surface the problem to the user — flagged, not yet
  investigated/fixed.
- **iOS SQLCipher "file is not a database" (SQLite code 26) key-mismatch — long
  investigation, structural fix landed but not yet device-verified.** Root-caused
  through several rounds to real bugs in `flutter_secure_storage` itself (orphaned
  WAL/SHM sidecars not cleaned on reset — fixed; duplicate Keychain items from the
  package's own accessibility/synchronizable handling across app versions —
  documented in upstream issues #960/#573/#762). The structural fix: moved the DB
  key off `flutter_secure_storage` entirely onto a local first-party plugin
  (`packages/medkit_db_key_storage`, see "Data layer" above) with one fixed,
  never-varying Keychain attribute set, which makes that whole bug class
  impossible by construction rather than working around it. `main.dart`'s
  `_DatabaseErrorScreen` still leads with "restart the app" and only offers the
  destructive "reset local DB"/"restore from backup" buttons after 3 failed
  retries. **Not yet verified on a real device** — see "Post-migration Mac
  checklist" in "Build & release" below before assuming this is closed. Firebase
  Crashlytics (see "Diagnostics" above) is now wired specifically so any
  recurrence surfaces a real stack trace instead of another blind guess.

## Commands

```bash
flutter pub get                 # after any pubspec.yaml change
flutter run                     # iOS run needs a Mac + Xcode
flutter analyze                 # static check — run after every source change
flutter gen-l10n                # regenerate AppLocalizations after any ARB edit
dart run build_runner build --delete-conflicting-outputs   # after any Drift schema change
flutter test                    # unit tests (crypto/sync only, see "Known gaps")
```

## Where to look for more context

- `docs/l10n_glossary.md` — translation ambiguity glossary, keep it current.
- `docs/multifamily_billing_plan.md` — full multi-family/billing design, resolved
  open questions included; read before continuing that scope.
- `medkit-backend/DEPLOY.md` — backend deployment steps (separate repo, not
  git-tracked here).
- Claude's persistent memory (project-level, cross-session) has additional
  narrower notes — worktree gotchas, verification-workflow preferences, and the
  historical narrative of the privacy-first architecture rework. This file
  (`CLAUDE.md`) is the current-state/rules reference; memory holds session
  continuity notes that are more granular or time-sensitive.
