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
    int parsedId = 0;
    if (json['id'] is int) {
      parsedId = json['id'];
    } else if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    bool verified = false;
    final v = json['isVerified'] ?? json['is_verified'];
    if (v is bool) {
      verified = v;
    } else if (v is int) {
      verified = v == 1;
    } else if (v is String) {
      verified = v.toLowerCase() == 'true' || v == '1';
    }

    return UserModel(
      id: parsedId,
      name: (json['name'] ?? json['username'] ?? 'User').toString(),
      email: json['email']?.toString(),
      isVerified: verified,
      profileImage: json['profileImage']?.toString() ??
          json['profile_image']?.toString() ??
          json['avatar']?.toString() ??
          json['image']?.toString(),
      coverImage: json['coverImage']?.toString() ??
          json['cover_image']?.toString(),
      bio: json['bio']?.toString(),
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

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    bool? isVerified,
    String? profileImage,
    String? coverImage,
    String? bio,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      bio: bio ?? this.bio,
    );
  }
}

