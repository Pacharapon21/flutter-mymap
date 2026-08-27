import 'dart:convert';

class FriendModel {
  final int id;
  final String name;
  final DateTime addedAt;

  FriendModel({required this.id, required this.name, required this.addedAt});

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      addedAt: DateTime.tryParse(json['addedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'addedAt': addedAt.toIso8601String()};
  }

  static List<FriendModel> fromJsonList(String jsonString) {
    final List<dynamic> list = jsonDecode(jsonString);
    return list.map((e) => FriendModel.fromJson(e)).toList();
  }

  static String toJsonList(List<FriendModel> friends) {
    return jsonEncode(friends.map((f) => f.toJson()).toList());
  }
}
