class User {
  final int id;
  final String name;
  final String? email;
  final String? jobTitle;
  final String? avatarPath;
  final String? bio;
  final bool isOnline;

  const User({
    required this.id,
    required this.name,
    this.email,
    this.jobTitle,
    this.avatarPath,
    this.bio,
    this.isOnline = false,
  });
}
