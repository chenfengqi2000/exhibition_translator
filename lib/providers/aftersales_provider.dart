import 'package:flutter/material.dart';
import '../services/aftersales_service.dart';

/// 售后记录的 API 缓存层。
/// 数据来自后端数据库，按登录用户隔离，重启后仍持久。
class AftersalesProvider extends ChangeNotifier {
  final AftersalesService _service;

  AftersalesProvider(this._service);

  List<Map<String, dynamic>> _records = [];
  bool _loaded = false;

  List<Map<String, dynamic>> get records => List.unmodifiable(_records);

  // ─── 加载 ──────────────────────────────────────────────────────────

  Future<void> loadAftersales() async {
    try {
      final result = await _service.listAftersales();
      _records = List<Map<String, dynamic>>.from(result['list'] ?? []);
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // 网络失败不影响其他 UI，保留旧缓存
    }
  }

  /// 确保至少加载过一次
  Future<void> ensureLoaded() async {
    if (!_loaded) await loadAftersales();
  }

  // ─── 查询（基于本地缓存）──────────────────────────────────────────

  /// 根据订单 ID 从缓存查找售后记录
  Map<String, dynamic>? findByOrderId(int orderId) {
    for (final r in _records) {
      if (r['orderId'] == orderId) return r;
    }
    return null;
  }

  /// 是否有未结束的售后（status == 'processing'）
  bool isOrderAftersalesOpen(int orderId) {
    final r = findByOrderId(orderId);
    return r != null && (r['status'] as String? ?? '') == 'processing';
  }

  // ─── 新增（提交后更新缓存）─────────────────────────────────────────

  Future<Map<String, dynamic>> createAftersale({
    required int orderId,
    required String type,
    required String description,
    List<String> evidenceImages = const [],
  }) async {
    final record = await _service.createAftersale(
      orderId: orderId,
      type: type,
      description: description,
      evidenceImages: evidenceImages,
    );
    _records.insert(0, record);
    notifyListeners();
    return record;
  }

  // ─── 重置（登出时调用）────────────────────────────────────────────

  void clear() {
    _records = [];
    _loaded = false;
    notifyListeners();
  }
}
