import 'package:dio/dio.dart';
import 'api_client.dart';

class AftersalesService {
  final ApiClient _client;
  AftersalesService(this._client);

  /// POST /aftersales/upload-evidence — upload raw bytes (works on all platforms)
  Future<String> uploadEvidenceBytes(List<int> bytes, String filename) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final result = await _client.upload('/aftersales/upload-evidence', formData: formData);
    return (result as Map)['url'] as String;
  }

  /// POST /aftersales
  Future<Map<String, dynamic>> createAftersale({
    required int orderId,
    required String type,
    required String description,
    List<String> evidenceImages = const [],
  }) async {
    final result = await _client.post('/aftersales', data: {
      'orderId': orderId,
      'type': type,
      'description': description,
      'evidenceImages': evidenceImages,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  /// GET /aftersales
  Future<Map<String, dynamic>> listAftersales({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    final result = await _client.get('/aftersales', queryParameters: params);
    return Map<String, dynamic>.from(result as Map);
  }

  /// GET /aftersales/:id
  Future<Map<String, dynamic>> getAftersale(int id) async {
    final result = await _client.get('/aftersales/$id');
    return Map<String, dynamic>.from(result as Map);
  }

  /// GET /aftersales/order/:orderId
  /// Returns null if no aftersale exists for this order
  Future<Map<String, dynamic>?> getAftersaleByOrder(int orderId) async {
    final result = await _client.get('/aftersales/order/$orderId');
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }
}
