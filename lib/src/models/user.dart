class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String bio;
  final String avatarUrl;
  final int following;
  final int followers;
  final int postsCount;
  final bool isPrivate;
  final String website;
  final String gender;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.bio,
    required this.avatarUrl,
    this.following = 0,
    this.followers = 0,
    this.postsCount = 0,
    this.isPrivate = false,
    this.website = '',
    this.gender = '',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final uMap = (json['user'] is Map<String, dynamic>) ? json['user'] as Map<String, dynamic> : json;
    final countMap = uMap['_count'] is Map ? uMap['_count'] : (json['_count'] is Map ? json['_count'] : null);
    
    return AppUser(
      id: (uMap['id'] ?? uMap['_id'] ?? uMap['userId'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      username: (uMap['username'] ?? json['username'] ?? 'user').toString(),
      fullName: (uMap['fullName'] ?? uMap['name'] ?? json['fullName'] ?? uMap['username'] ?? json['username'] ?? 'User').toString(),
      email: (uMap['email'] ?? json['email'] ?? '').toString(),
      bio: (uMap['bio'] ?? json['bio'] ?? '').toString(),
      avatarUrl: (uMap['avatarUrl'] ?? json['avatarUrl'] ?? '').toString(),
      following: countMap?['following'] ?? uMap['following'] ?? json['following'] ?? 0,
      followers: countMap?['followers'] ?? uMap['followers'] ?? json['followers'] ?? 0,
      postsCount: countMap?['posts'] ?? uMap['postsCount'] ?? json['postsCount'] ?? 0,
      isPrivate: uMap['isPrivate'] ?? json['isPrivate'] ?? false,
      website: (uMap['website'] ?? json['website'] ?? '').toString(),
      gender: (uMap['gender'] ?? json['gender'] ?? '').toString(),
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
        'postsCount': postsCount,
        'isPrivate': isPrivate,
        'website': website,
        'gender': gender,
      };

  AppUser copyWith({
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    int? following,
    int? followers,
    int? postsCount,
    bool? isPrivate,
    String? website,
    String? gender,
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
      postsCount: postsCount ?? this.postsCount,
      isPrivate: isPrivate ?? this.isPrivate,
      website: website ?? this.website,
      gender: gender ?? this.gender,
    );
  }
}
