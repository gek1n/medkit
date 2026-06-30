enum FamilyMemberRole { owner, member, dependent }
enum DependentAccessType { link, code, none }

class FamilyMember {
  final String id;
  final String name;
  final String avatar;
  final FamilyMemberRole role;
  final int takenToday;
  final int totalToday;
  final DependentAccessType? accessType;
  final int fontSize;

  const FamilyMember({
    required this.id, required this.name, required this.avatar,
    required this.role, required this.takenToday, required this.totalToday,
    this.accessType, this.fontSize = 2,
  });

  bool get isDependent => role == FamilyMemberRole.dependent;
  double get adherence => totalToday > 0 ? takenToday / totalToday : 0;
}
