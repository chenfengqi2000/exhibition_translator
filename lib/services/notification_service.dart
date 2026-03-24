import 'api_client.dart';

class NotificationService {
  final ApiClient _client;
  NotificationService(this._client);

  /// GET /notifications — 通知列表
  Future<Map<String, dynamic>> listNotifications({
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (isRead != null) params['isRead'] = isRead.toString();
    final result = await _client.get('/notifications', queryParameters: params);
    return Map<String, dynamic>.from(result);
  }

  /// GET /notifications/unread-count — 未读通知数
  Future<int> getUnreadCount() async {
    final result = await _client.get('/notifications/unread-count');
    return (result['count'] as num?)?.toInt() ?? 0;
  }

  /// PUT /notifications/:id/read — 标记单条为已读
  Future<void> markAsRead(int notificationId) async {
    await _client.put('/notifications/$notificationId/read');
  }

  /// POST /notifications/read-all — 全部标记已读
  Future<void> markAllRead() async {
    await _client.post('/notifications/read-all');
  }
}
