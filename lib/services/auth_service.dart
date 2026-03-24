import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  /// 登录 — 符合 api-contract.md 3.1
  Future<LoginResult> login(String phone, String password) async {
    final data = await _client.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return LoginResult(
      token: data['accessToken'],
      user: User.fromJson(data['user']),
    );
  }

  /// 获取当前用户信息 — 符合 api-contract.md 3.2
  Future<User> getCurrentUser() async {
    final data = await _client.get('/auth/me');
    return User.fromJson(data);
  }

  /// 注册
  Future<LoginResult> register(String name, String phone, String password) async {
    final data = await _client.post('/auth/register', data: {
      'name': name,
      'phone': phone,
      'password': password,
    });
    return LoginResult(
      token: data['accessToken'],
      user: User.fromJson(data['user']),
    );
  }

  /// 更新角色
  Future<void> updateRole(String role) async {
    await _client.put('/auth/role', data: {'role': role});
  }

  /// 登出
  Future<void> logout() async {
    await _client.post('/auth/logout');
  }
}

class LoginResult {
  final String token;
  final User user;
  LoginResult({required this.token, required this.user});
}
