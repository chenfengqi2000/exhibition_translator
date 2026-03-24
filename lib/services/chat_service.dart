import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _client;
  ChatService(this._client);

  /// POST /chat/conversations — 获取或创建会话
  Future<Map<String, dynamic>> getOrCreateConversation(int otherUserId) async {
    final result = await _client.post(
      '/chat/conversations',
      data: {'otherUserId': otherUserId},
    );
    return Map<String, dynamic>.from(result);
  }

  /// GET /chat/conversations — 会话列表
  Future<Map<String, dynamic>> listConversations({
    int page = 1,
    int pageSize = 50,
  }) async {
    final result = await _client.get(
      '/chat/conversations',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return Map<String, dynamic>.from(result);
  }

  /// GET /chat/conversations/:id/messages — 消息列表
  Future<Map<String, dynamic>> listMessages(
    int conversationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final result = await _client.get(
      '/chat/conversations/$conversationId/messages',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return Map<String, dynamic>.from(result);
  }

  /// POST /chat/conversations/:id/messages — 发送消息
  Future<Map<String, dynamic>> sendMessage(
    int conversationId, {
    String msgType = 'TEXT',
    required String content,
    int? refRequestId,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{
      'msgType': msgType,
      'content': content,
    };
    if (refRequestId != null) data['refRequestId'] = refRequestId;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    final result = await _client.post(
      '/chat/conversations/$conversationId/messages',
      data: data,
    );
    return Map<String, dynamic>.from(result);
  }

  /// POST /chat/upload-image — 上传聊天图片（跨平台：bytes 方式）
  Future<String> uploadChatImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final result = await _client.upload('/chat/upload-image', formData: formData);
    return (result as Map)['imageUrl'] as String;
  }

  /// 发送图片消息：先上传，再发消息（跨平台）
  Future<Map<String, dynamic>> sendImageMessage(
    int conversationId, {
    required Uint8List bytes,
    required String fileName,
  }) async {
    final imageUrl = await uploadChatImage(bytes: bytes, fileName: fileName);
    return sendMessage(
      conversationId,
      msgType: 'IMAGE',
      content: '[图片]',
      imageUrl: imageUrl,
    );
  }

  /// GET /chat/unread-count — 未读消息总数
  Future<int> getUnreadCount() async {
    final result = await _client.get('/chat/unread-count');
    return (result['count'] as num?)?.toInt() ?? 0;
  }
}
