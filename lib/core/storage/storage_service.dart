import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = '@auth_token';
  static const _refreshTokenKey = '@refresh_token';
  static const _userKey = '@user_profile';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _secureStorage.write(key: _tokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> saveUserJson(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userJson);
  }

  Future<String?> getUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
