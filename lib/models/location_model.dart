import 'user_model.dart';

class LocationModel {
  final int id;
  final double lat;
  final double lng;
  final String? locationName;
  final String? address;
  final double? accuracy;
  final String? description;
  final String? imageUrl;
  final String createdAt;
  final UserModel? user;

  LocationModel({
    required this.id,
    required this.lat,
    required this.lng,
    this.locationName,
    this.address,
    this.accuracy,
    this.description,
    this.imageUrl,
    required this.createdAt,
    this.user,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] ?? 0,
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      locationName: json['locationName'],
      address: json['address'],
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      description: json['description'],
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'] ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lat': lat,
      'lng': lng,
      'locationName': locationName,
      'address': address,
      'accuracy': accuracy,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'user': user?.toJson(),
    };
  }
}
