import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// 订单卡片 — 通用组件，基于 Map 数据
/// TODO: 接入 Order 模型后优化
class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E2A4A).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '订单号: ${order['orderNo'] ?? order['id'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8F9BB3)),
                ),
                StatusBadge(status: order['status'] ?? ''),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order['expoName'] ?? '',
              style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF8F9BB3)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order['venue'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8F9BB3)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF8F9BB3)),
                const SizedBox(width: 4),
                Text(
                  order['dateRange'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8F9BB3)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
