import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend_model.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _friendsKey = 'friends_list';

  // ========================
  // TOKEN
  // ========================
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ========================
  // FRIENDS
  // ========================
  Future<List<FriendModel>> getFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_friendsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return FriendModel.fromJsonList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFriends(List<FriendModel> friends) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_friendsKey, FriendModel.toJsonList(friends));
  }

  Future<bool> addFriend(FriendModel friend) async {
    final friends = await getFriends();
    // ตรวจสอบว่ามีเพื่อนนี้แล้วหรือยัง
    if (friends.any((f) => f.id == friend.id)) return false;
    friends.add(friend);
    await saveFriends(friends);
    return true;
  }

  Future<void> removeFriend(int userId) async {
    final friends = await getFriends();
    friends.removeWhere((f) => f.id == userId);
    await saveFriends(friends);
  }

  Future<bool> isFriend(int userId) async {
    final friends = await getFriends();
    return friends.any((f) => f.id == userId);
  }
}
