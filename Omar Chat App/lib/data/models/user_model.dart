class UserModel {
  final int? id;
  final String name;
  final String? email;
  final String? jobTitle;
  final String? avatarPath;
  final String? bio;
  final bool isOnline;

  const UserModel({
    this.id,
    required this.name,
    this.email,
    this.jobTitle,
    this.avatarPath,
    this.bio,
    this.isOnline = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'job_title': jobTitle,
        'avatar_path': avatarPath,
        'bio': bio,
        'is_online': isOnline ? 1 : 0,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        email: map['email'] as String?,
        jobTitle: map['job_title'] as String?,
        avatarPath: map['avatar_path'] as String?,
        bio: map['bio'] as String?,
        isOnline: (map['is_online'] as int? ?? 0) == 1,
      );

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? jobTitle,
    String? avatarPath,
    String? bio,
    bool? isOnline,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        jobTitle: jobTitle ?? this.jobTitle,
        avatarPath: avatarPath ?? this.avatarPath,
        bio: bio ?? this.bio,
        isOnline: isOnline ?? this.isOnline,
      );
}
