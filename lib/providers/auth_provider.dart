import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storage;

  User? _user;
  String? _role;
  bool _isLoading = true;
  String? _error;

  AuthProvider({
    required AuthService authService,
    required StorageService storage,
  })  : _authService = authService,
        _storage = storage;

  User? get user => _user;
  String? get role => _role;
  bool get isLoggedIn => _storage.token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 应用启动时调用：检查是否已登录
  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final token = _storage.token;
    if (token == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _user = await _authService.getCurrentUser();
      _role = _user!.role;
      if (_role != null) {
        await _storage.setRole(_role!);
      }
    } catch (_) {
      // token 无效，清除
      await _storage.clearAll();
      _user = null;
      _role = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 登录
  Future<void> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(phone, password);
      await _storage.setToken(result.token);
      _user = result.user;
      _role = result.user.role;
      if (_role != null) {
        await _storage.setRole(_role!);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 注册并自动登录
  Future<void> register(String name, String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.register(name, phone, password);
      await _storage.setToken(result.token);
      _user = result.user;
      _role = result.user.role;  // 新注册用户 role 为 null
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 设置角色：同步到后端 + 本地持久化
  Future<void> setRole(String role) async {
    try {
      await _authService.updateRole(role);
    } catch (_) {
      // 网络失败时仍然本地生效，不阻断用户
    }
    _role = role;
    await _storage.setRole(role);
    notifyListeners();
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    await _storage.clearAll();
    _user = null;
    _role = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
