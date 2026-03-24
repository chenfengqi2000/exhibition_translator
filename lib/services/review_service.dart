import 'api_client.dart';

class ReviewService {
  final ApiClient _client;
  ReviewService(this._client);

  /// POST /employer/orders/:id/review — api-contract (review section)
  Future<Map<String, dynamic>> submitReview({
    required int orderId,
    required int rating,
    required String content,
  }) async {
    final result = await _client.post(
      '/employer/orders/$orderId/review',
      data: {'rating': rating, 'content': content},
    );
    return Map<String, dynamic>.from(result);
  }

  /// GET /marketplace/translators/:id/reviews — api-contract (review section)
  Future<Map<String, dynamic>> listTranslatorReviews(
    String translatorId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _client.get(
      '/marketplace/translators/$translatorId/reviews',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return Map<String, dynamic>.from(result);
  }

  /// GET /translator/reviews — 翻译员查看自己收到的评价
  Future<Map<String, dynamic>> listMyReviews({
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _client.get(
      '/translator/reviews',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return Map<String, dynamic>.from(result);
  }
}
