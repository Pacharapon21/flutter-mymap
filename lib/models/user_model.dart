class UserModel {
  final int id;
  final String name;
  final String? email;
  final bool isVerified;
  final String? profileImage;
  final String? coverImage;
  final String? bio;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.isVerified = false,
    this.profileImage,
    this.coverImage,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      isVerified: json['isVerified'] ?? false,
      profileImage: json['profileImage'],
      coverImage: json['coverImage'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isVerified': isVerified,
      'profileImage': profileImage,
      'coverImage': coverImage,
      'bio': bio,
    };
  }
}
