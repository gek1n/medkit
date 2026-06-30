enum IntakeStatus { pending, taken, skipped }

class MedIntake {
  final String id;
  final String medicationId;
  final String medicationName;
  final String medicationDose;
  final String medicationEmoji;
  final DateTime scheduledAt;
  final IntakeStatus status;
  final DateTime? takenAt;

  const MedIntake({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.medicationDose,
    required this.medicationEmoji,
    required this.scheduledAt,
    required this.status,
    this.takenAt,
  });

  bool get isPending => status == IntakeStatus.pending;
  bool get isTaken => status == IntakeStatus.taken;
  bool get isSkipped => status == IntakeStatus.skipped;

  MedIntake copyWith({IntakeStatus? status, DateTime? takenAt}) => MedIntake(
        id: id,
        medicationId: medicationId,
        medicationName: medicationName,
        medicationDose: medicationDose,
        medicationEmoji: medicationEmoji,
        scheduledAt: scheduledAt,
        status: status ?? this.status,
        takenAt: takenAt ?? this.takenAt,
      );
}
