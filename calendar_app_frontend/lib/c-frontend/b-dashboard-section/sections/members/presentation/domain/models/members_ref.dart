// c-frontend/b-calendar-section/screens/group-screen/members/models/member_ref.dart
class MemberRef {
  final String username;
  final String role; // 'owner' | 'admin' | 'member' | custom
  final String statusToken; // 'Accepted' | 'Pending' | 'NotAccepted'
  final String ownerId;
  const MemberRef(
      {required this.username,
      required this.role,
      required this.statusToken,
      required this.ownerId});
}
