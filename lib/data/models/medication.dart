enum MedForm { tablet, capsule, syrup, drops, cream, inhaler, injection, other }
enum FoodRelation { before, after, with_, any }

extension MedFormLabel on MedForm {
  String get label => switch (this) {
    MedForm.tablet => 'Таблетки', MedForm.capsule => 'Капсули',
    MedForm.syrup => 'Сироп', MedForm.drops => 'Краплі',
    MedForm.cream => 'Мазь/крем', MedForm.inhaler => 'Інгалятор',
    MedForm.injection => 'Ін\'єкція', MedForm.other => 'Інше',
  };
  String get emoji => switch (this) {
    MedForm.tablet || MedForm.capsule || MedForm.other => '💊',
    MedForm.syrup => '🍶', MedForm.drops => '💧',
    MedForm.cream => '🧴', MedForm.inhaler => '💨',
    MedForm.injection => '💉',
  };
}

extension FoodRelationLabel on FoodRelation {
  String get label => switch (this) {
    FoodRelation.before => 'До їжі', FoodRelation.after => 'Після їжі',
    FoodRelation.with_ => 'Під час їжі', FoodRelation.any => 'Незалежно від їжі',
  };
}

class Medication {
  final String id;
  final String name;
  final MedForm form;
  final String dose;
  final FoodRelation foodRelation;
  final String? instructions;
  final int totalCount;
  final int remainingCount;
  final bool isActive;
  final DateTime createdAt;

  const Medication({
    required this.id, required this.name, required this.form,
    required this.dose, required this.foodRelation, this.instructions,
    required this.totalCount, required this.remainingCount,
    this.isActive = true, required this.createdAt,
  });

  double get remainingPercent => totalCount > 0 ? remainingCount / totalCount : 0;

  Medication copyWith({String? name, MedForm? form, String? dose, FoodRelation? foodRelation,
      String? instructions, int? totalCount, int? remainingCount, bool? isActive}) {
    return Medication(
      id: id, name: name ?? this.name, form: form ?? this.form,
      dose: dose ?? this.dose, foodRelation: foodRelation ?? this.foodRelation,
      instructions: instructions ?? this.instructions, totalCount: totalCount ?? this.totalCount,
      remainingCount: remainingCount ?? this.remainingCount, isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
