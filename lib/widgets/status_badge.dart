import 'package:flutter/material.dart';

/// 通用状态标签 — 使用文档统一的 UPPER_CASE 枚举值
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: config.textColor,
          height: 1.2,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'PENDING_QUOTE':
        return _StatusConfig(label: '待报价', textColor: const Color(0xFFF54900), backgroundColor: const Color(0xFFFFEDD4));
      case 'PENDING_CONFIRM':
        return _StatusConfig(label: '待确认', textColor: const Color(0xFF155DFC), backgroundColor: const Color(0xFFDBEAFE));
      case 'CONFIRMED':
        return _StatusConfig(label: '已确认', textColor: const Color(0xFF00A63E), backgroundColor: const Color(0xFFDCFCE7));
      case 'IN_SERVICE':
        return _StatusConfig(label: '服务中', textColor: const Color(0xFF155DFC), backgroundColor: const Color(0xFFDBEAFE));
      case 'COMPLETED':
        return _StatusConfig(label: '已完成', textColor: const Color(0xFF00A63E), backgroundColor: const Color(0xFFDCFCE7));
      case 'CANCELLED':
        return _StatusConfig(label: '已取消', textColor: const Color(0xFF6B7280), backgroundColor: const Color(0xFFF3F4F6));
      default:
        return _StatusConfig(label: status, textColor: const Color(0xFF6B7280), backgroundColor: const Color(0xFFF3F4F6));
    }
  }
}

class _StatusConfig {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  _StatusConfig({required this.label, required this.textColor, required this.backgroundColor});
}
