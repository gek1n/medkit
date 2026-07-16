# Localization glossary — ambiguous / abbreviated terms

Notes for translating `lib/l10n/app_uk.arb` into any other language. These are
terms that read one way out of context but mean something specific in this
app. Check this file before translating the keys listed below — the ARB file
itself is not annotated (kept clean per project convention); this glossary is
the source of context.

## "Прийом" — two unrelated meanings in this app

Ukrainian "прийом" is used for both **medication dose/intake** and **doctor's
appointment**. These are unrelated concepts in the app and must not be
conflated in translation.

- `intakeLabel` = `"Прийом"` (standalone, no qualifier) → **medication dose /
  intake** (shown as an info-row label next to a medication's dosing
  schedule, e.g. "Intake: daily, 2×"). NOT "Appointment".
- `skipIntakeAction` = `"Пропустити прийом"` → **skip this medication dose**
  ("Skip dose"), not "skip appointment".
- `sectionAppointments` = `"Прийоми лікарів"` → **doctor appointments**
  (disambiguated by "лікарів" = "of doctors").
- `notifAppointmentTitle` = `"🩺 Прийом лікаря"` → **doctor's appointment**
  (disambiguated by "лікаря" = "doctor's", plus the 🩺 stethoscope emoji).
- `diarySummaryHint` = `"Зрізи + симптоми + прийоми за місяць"` → the
  "прийоми" here means **medication doses/intakes** (summarized alongside
  wellbeing check-ins and symptoms for a monthly diary shown to a doctor),
  not appointments.
- `reminderOffsetSub` = `"Отримувати за N хв до прийому"` — this is a
  **generic notification-settings description** that applies to reminders
  for medications, activities, and appointments alike. Translate loosely as
  "N minutes before the reminder" / "before the scheduled time", not
  literally "before the appointment" — the setting is not medication- or
  appointment-specific.

## "Зріз" (literally "a slice/cross-section") = wellbeing check-in

Always refers to a scheduled **wellbeing/mood check-in slot**, never a
literal slice or cross-section. Several keys use it standalone without the
qualifying word "самопочуття" ("wellbeing") right next to it — translate all
of these consistently as "check-in" (or "wellbeing check-in" where there's
room):
`wellbeingSlotNumberLabel`, `addWellbeingSlotAction`, `noWellbeingLogsTitle`,
`noWellbeingLogsHint`, `wellbeingSlotsTitle`, `notifWellbeingTitle`.

## "Курс" = medication treatment course

Always means a course of medication treatment (start date → end date, or
ongoing), never "a course of study" or any other sense of "course". Keys:
`courseOngoing`, `courseFinished`, `courseNounLabel`, `stopCourseConfirmTitle`,
`courseAvailableLabel`, `enoughForCourseLabel`, `courseStagesLabel`,
`courseDaysLeft`, `courseRangeLabel`.

## Literal placeholder-looking letters "N" / "M" — NOT real variables

A few ARB values contain a literal capital letter "N" (or "M") as a
human-readable stand-in inside otherwise-static UI copy — this is different
from the real ICU `{n}`/`{count}` interpolation used elsewhere in the file.
Keep the literal letter as-is when translating (English also uses "every N
days" idiomatically, so no change in convention needed):
- `repeatEveryN` = `"кожні N днів"` → "every N days"
- `everyNHoursLabel` = `"Кожні N годин"` → "Every N hours"
- `everyNDaysOptionLabel` = `"Кожні N днів"` → "Every N days"
- `cycleExampleLabel` = `"N днів пити — M днів перерва"` → "N days on — M
  days off" (two placeholder letters here, N and M)

Do not confuse these with the real interpolated siblings that use actual
`{n}`/`{count}` placeholders, e.g. `repeatEveryNCap` = `"Кожні {n} дні"`.

## Short unit-abbreviation suffixes (medUnit*)

These are Ukrainian pharmacy-label abbreviations meant to sit right after a
number (e.g. "5 табл." = "5 tabs"). Keep the English equivalents similarly
short — don't spell out the full word, it breaks the compact number+unit
layout these are used in:
- `medUnitTablet` = `"табл."` → "tab."
- `medUnitCapsule` = `"капс."` → "cap."
- `medUnitMl` = `"мл"` → "ml"
- `medUnitDrops` = `"крап."` → "gtt" or "drop(s)" (short form)
- `medUnitGram` = `"г"` → "g"
- `medUnitInhale` = `"вдих"` → "puff"
- `medUnitSuppository` = `"свіча"` → "supp."
- `medUnitVial` = `"фл."` → "vial"
- `medUnitPiece` = `"шт."` → "pc."

## Bare time-unit abbreviations

- `daysSuffix` = `"дн."` → abbreviation for "days" (not months/dates) → "d."
  or "days" depending on space available at the call site (used right after
  a number in duration steppers).
- `hoursSuffix` = `"год"` → abbreviation for "hours" (not "year" — Ukrainian
  "рік" is year, "год" is hours) → "h" or "hrs".
