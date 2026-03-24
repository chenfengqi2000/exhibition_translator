class ApiConfig {
  // Base URL — 符合 api-contract.md 1.1
  static const String baseUrl = 'http://localhost:8080/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
