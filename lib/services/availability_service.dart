import 'api_client.dart';

/// 档期管理服务 — 对应 api-contract.md 6.8 / 6.9
class AvailabilityService {
  final ApiClient _client;
  AvailabilityService(this._client);

  /// GET /translator/availability?year=&month=
  Future<Map<String, dynamic>> getAvailability({
    required int year,
    required int month,
  }) async {
    final result = await _client.get(
      '/translator/availability',
      queryParameters: {'year': year, 'month': month},
    );
    return Map<String, dynamic>.from(result);
  }

  /// POST /translator/availability/batch
  Future<void> batchSetAvailability({
    required List<String> dates,
    required String status,
    String? city,
    String? venue,
    String? note,
  }) async {
    final data = <String, dynamic>{
      'dates': dates,
      'status': status,
    };
    if (city != null && city.isNotEmpty) data['city'] = city;
    if (venue != null && venue.isNotEmpty) data['venue'] = venue;
    if (note != null && note.isNotEmpty) data['note'] = note;
    await _client.post('/translator/availability/batch', data: data);
  }

  /// PUT /translator/profile (only restWeekdays)
  Future<void> saveRestWeekdays(List<int> restWeekdays) async {
    await _client.put('/translator/profile', data: {
      'restWeekdays': restWeekdays,
    });
  }
}
