import 'package:flutter/foundation.dart';
import '../models/translator.dart';
import '../services/favorite_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final FavoriteService _service;

  /// 收藏列表（用于"我的收藏"页面）
  List<Translator> _favorites = [];
  bool _isLoading = false;
  String? _error;

  /// 本地缓存的已收藏 translatorId 集合，用于列表页/详情页快速判断状态
  final Set<String> _favoriteIds = {};

  FavoriteProvider({required FavoriteService service}) : _service = service;

  List<Translator> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isFavorited(String translatorId) => _favoriteIds.contains(translatorId);

  /// 加载收藏列表，同时更新本地 ID 缓存
  Future<void> loadFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _favorites = await _service.listFavorites();
      _favoriteIds
        ..clear()
        ..addAll(_favorites.map((t) => t.id));
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 收藏 / 取消收藏，乐观更新本地状态后调用 API
  Future<void> toggleFavorite(String translatorId) async {
    final wasFavorited = _favoriteIds.contains(translatorId);

    // 乐观更新
    if (wasFavorited) {
      _favoriteIds.remove(translatorId);
      _favorites.removeWhere((t) => t.id == translatorId);
    } else {
      _favoriteIds.add(translatorId);
    }
    notifyListeners();

    try {
      if (wasFavorited) {
        await _service.removeFavorite(translatorId);
      } else {
        await _service.addFavorite(translatorId);
      }
    } catch (_) {
      // 回滚
      if (wasFavorited) {
        _favoriteIds.add(translatorId);
      } else {
        _favoriteIds.remove(translatorId);
      }
      notifyListeners();
    }
  }

  /// 初始化时从 translators 列表预填充已收藏 ID（来自 isFavorited 字段）
  void syncFromTranslatorList(List<Translator> translators) {
    for (final t in translators) {
      if (t.isFavorited) {
        _favoriteIds.add(t.id);
      }
    }
    notifyListeners();
  }
}
