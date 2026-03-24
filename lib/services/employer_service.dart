import 'api_client.dart';

class EmployerService {
  final ApiClient _client;
  EmployerService(this._client);

  /// POST /employer/requests — api-contract 5.1
  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> data) async {
    final result = await _client.post('/employer/requests', data: data);
    return Map<String, dynamic>.from(result);
  }

  /// GET /employer/requests — api-contract 5.2
  Future<Map<String, dynamic>> listRequests({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (status != null && status.isNotEmpty) params['status'] = status;
    final result = await _client.get('/employer/requests', queryParameters: params);
    return Map<String, dynamic>.from(result);
  }

  /// GET /employer/requests/:id — api-contract 5.3
  Future<Map<String, dynamic>> getRequestDetail(int id) async {
    final result = await _client.get('/employer/requests/$id');
    return Map<String, dynamic>.from(result);
  }

  /// GET /employer/orders — api-contract 5.3
  Future<Map<String, dynamic>> listOrders({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (status != null && status.isNotEmpty) params['status'] = status;
    final result = await _client.get('/employer/orders', queryParameters: params);
    return Map<String, dynamic>.from(result);
  }

  /// GET /employer/orders/:id — api-contract 5.4
  Future<Map<String, dynamic>> getOrderDetail(int id) async {
    final result = await _client.get('/employer/orders/$id');
    return Map<String, dynamic>.from(result);
  }

  /// POST /employer/orders/:requestId/confirm-quote — api-contract 5.5
  Future<Map<String, dynamic>> confirmQuote(int requestId, int quoteId) async {
    final result = await _client.post(
      '/employer/orders/$requestId/confirm-quote',
      data: {'quoteId': quoteId},
    );
    return Map<String, dynamic>.from(result);
  }

  /// POST /employer/orders/:orderId/confirm-completion — api-contract 5.7
  Future<void> confirmOrderCompletion(int orderId) async {
    await _client.post('/employer/orders/$orderId/confirm-completion');
  }

  /// POST /employer/requests/:id/dev-approve — 开发环境模拟审核通过需求
  Future<Map<String, dynamic>> devApproveRequest(int requestId) async {
    final result = await _client.post('/employer/requests/$requestId/dev-approve');
    return Map<String, dynamic>.from(result);
  }
}
