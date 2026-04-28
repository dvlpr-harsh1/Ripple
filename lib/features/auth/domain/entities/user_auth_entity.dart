class UserAuthEntity {
  final String id;
  final String email;
  final String? displayName;
  final String? imgUrl;
  final List? profileViews;

  const UserAuthEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.imgUrl,
    this.profileViews,
  });
}
