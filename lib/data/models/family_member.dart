enum FamilyMemberRole { owner, member, dependent }

class FamilyMember {
  final String id;
  final String name;
  final String avatar;
  final FamilyMemberRole role;
  final int takenToday;
  final int totalToday;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.avatar,
    required this.role,
    required this.takenToday,
    required this.totalToday,
  });

  double get adherence => totalToday > 0 ? takenToday / totalToday : 0;
  bool get isOwner => role == FamilyMemberRole.owner;
}
