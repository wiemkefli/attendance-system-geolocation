import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _keyUserType = 'user_type';
  static const _keyAdminToken = 'admin_token';
  static const _keyStudentToken = 'token';
  static const _keyStudentGroupId = 'group_id';

  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserType);
  }

  static Future<void> setUserType(String? userType) async {
    final prefs = await SharedPreferences.getInstance();
    if (userType == null || userType.isEmpty) {
      await prefs.remove(_keyUserType);
      return;
    }
    await prefs.setString(_keyUserType, userType);
  }

  static Future<String?> getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAdminToken);
  }

  static Future<void> setAdminToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_keyAdminToken);
      return;
    }
    await prefs.setString(_keyAdminToken, token);
  }

  static Future<String?> getStudentToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStudentToken);
  }

  static Future<int?> getStudentGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStudentGroupId);
  }

  static Future<void> setStudentSession({
    required String token,
    required int groupId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStudentToken, token);
    await prefs.setInt(_keyStudentGroupId, groupId);
  }

  static Future<void> clearStudentSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStudentToken);
    await prefs.remove(_keyStudentGroupId);
  }
}

