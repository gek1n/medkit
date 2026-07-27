# App Review Information (App Store Connect) — чернетка

## App overview
Elly is a personal reminder and organizer app for individuals and their families. The app is available without login — all core features (medication reminders, general one-off/recurring reminders, wellbeing check-ins, activity tracking, and free-form archive notes) work immediately after onboarding, no account required.

## Data storage
By default, all user data is stored locally on the device only, encrypted (SQLCipher) — nothing leaves the device. Two features are fully optional and off by default:
- Cloud backup: if enabled, uploads an already-encrypted file directly to the user's own iCloud or Google Drive account, protected by a password the user sets. We never receive this file.
- Cross-device / family sync: if enabled, individually-encrypted rows are relayed through a server we operate so the user's own devices (or family members they've paired with) can exchange them. The server only ever sees ciphertext it cannot decrypt — the encryption key never leaves the user's device(s).

## Plans
All features are available on the Free plan. The only paid-plan exceptions are cross-device sync and multi-profile/family sharing (adding more than one local profile, or connecting with other people's devices) — both can be reviewed and activated from the Plans screen.

## Medical disclaimer
Elly is not a medical device and does not provide diagnoses, treatment advice, or medical consultations. It only helps users track and remember information they enter themselves (or that a doctor has already told them). The app's Terms of Use explicitly state it does not replace a doctor or pharmacist, and reminds users to consult a healthcare professional before making medical decisions.
