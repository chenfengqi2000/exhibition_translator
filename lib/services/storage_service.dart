import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyToken = 'auth_token';
  static const _keyRole = 'user_role';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? get token => _prefs.getString(_keyToken);

  Future<void> setToken(String token) => _prefs.setString(_keyToken, token);

  Future<void> clearToken() => _prefs.remove(_keyToken);

  String? get role => _prefs.getString(_keyRole);

  Future<void> setRole(String role) => _prefs.setString(_keyRole, role);

  Future<void> clearRole() => _prefs.remove(_keyRole);

  Future<void> clearAll() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyRole);
  }
}
