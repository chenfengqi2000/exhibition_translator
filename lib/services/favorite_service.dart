import '../models/translator.dart';
import 'api_client.dart';

class FavoriteService {
  final ApiClient _client;
  FavoriteService(this._client);

  /// POST /marketplace/translators/:id/favorite — api-contract 4.3
  Future<void> addFavorite(String translatorId) async {
    await _client.post('/marketplace/translators/$translatorId/favorite');
  }

  /// DELETE /marketplace/translators/:id/favorite — api-contract 4.4
  Future<void> removeFavorite(String translatorId) async {
    await _client.delete('/marketplace/translators/$translatorId/favorite');
  }

  /// GET /marketplace/favorites — api-contract 4.5
  Future<List<Translator>> listFavorites() async {
    final data = await _client.get('/marketplace/favorites');
    final list = data['list'] as List? ?? [];
    return list.map((e) => Translator.fromJson(e)).toList();
  }
}
