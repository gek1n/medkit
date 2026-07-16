import 'package:flutter/widgets.dart';

import 'l10n_ext.dart';

/// Довідник напрямків лікарів — контрольований словник замість вільного
/// тексту, щоб "Кардіолог" і "кардіолог" не розсипались на дві різні групи
/// при фільтрації історії за напрямком (`DoctorAppointments.doctorType`,
/// `LabResults.specialty`). "Інше" — запобіжник для рідкісних напрямків,
/// яких немає в списку: дозволяє ввести довільний текст замість блокування.
List<String> doctorSpecialties(BuildContext context) {
  final l10n = context.l10n;
  return [
    l10n.specialtyTherapist,
    l10n.specialtyPediatrician,
    l10n.specialtyFamilyDoctor,
    l10n.specialtyCardiologist,
    l10n.specialtyNeurologist,
    l10n.specialtyEndocrinologist,
    l10n.specialtyGastroenterologist,
    l10n.specialtyDermatologist,
    l10n.specialtyOphthalmologist,
    l10n.specialtyEnt,
    l10n.specialtyDentist,
    l10n.specialtyGynecologist,
    l10n.specialtyUrologist,
    l10n.specialtySurgeon,
    l10n.specialtyOrthopedist,
    l10n.specialtyTraumatologist,
    l10n.specialtyAllergist,
    l10n.specialtyImmunologist,
    l10n.specialtyPsychiatrist,
    l10n.specialtyPsychotherapist,
    l10n.specialtyUltrasoundDiagnostics,
    l10n.specialtyOncologist,
    l10n.specialtyRheumatologist,
    l10n.specialtyPulmonologist,
    l10n.specialtyNephrologist,
    l10n.specialtyPhlebologist,
    l10n.specialtyMammologist,
    l10n.specialtyOther,
  ];
}

String otherDoctorSpecialty(BuildContext context) => context.l10n.specialtyOther;
