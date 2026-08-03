class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String bio;
  final String avatarUrl;
  final int following;
  final int followers;
  final bool isPrivate;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.bio,
    required this.avatarUrl,
    this.following = 0,
    this.followers = 0,
    this.isPrivate = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      username: json['username'],
      fullName: json['fullName'],
      email: json['email'] ?? '',
      bio: json['bio'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      following: json['following'] ?? 0,
      followers: json['followers'] ?? 0,
      isPrivate: json['isPrivate'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'fullName': fullName,
        'email': email,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'following': following,
        'followers': followers,
        'isPrivate': isPrivate,
      };

  AppUser copyWith({
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    int? following,
    int? followers,
    bool? isPrivate,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}
