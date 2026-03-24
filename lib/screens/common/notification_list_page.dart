import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/state_widgets.dart';
import 'order_detail_page.dart';
import 'aftersales_detail_page.dart';
import '../translator/opportunity_detail_page.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = context.read<NotificationService>();
      final result = await service.listNotifications(pageSize: 50);
      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(result['list'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      await context.read<NotificationService>().markAllRead();
      await _loadNotifications();
    } catch (_) {}
  }

  Future<void> _onTapNotification(Map<String, dynamic> notif) async {
    final isRead = notif['isRead'] == true;
    final relatedType = notif['relatedType'] as String?;
    final role = context.read<AuthProvider>().role;

    if (!isRead) {
      final id = (notif['id'] as num?)?.toInt();
      if (id != null) {
        try {
          await context.read<NotificationService>().markAsRead(id);
          setState(() { notif['isRead'] = true; });
        } catch (_) {}
      }
    }

    if (!mounted) return;

    final relatedId = (notif['relatedId'] as num?)?.toInt();
    if (relatedId == null) return;

    if (relatedType == 'aftersale') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AftersalesDetailPage(aftersaleId: relatedId)),
      );
      return;
    }

    if (relatedType == 'request') {
      if (role == 'TRANSLATOR') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OpportunityDetailPage(requestId: relatedId)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailPage(requestId: relatedId, isEmployer: true)),
        );
      }
    } else if (relatedType == 'order') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailPage(orderId: relatedId, isEmployer: role == 'EMPLOYER'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '平台通知',
          style: TextStyle(color: AppColors.darkText, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('全部已读', style: TextStyle(fontSize: 13, color: AppColors.primary)),
          ),
        ],
      ),
      body: _buildBody(_notifications),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> merged) {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return ErrorRetryWidget(message: _error!, onRetry: _loadNotifications);
    if (merged.isEmpty) {
      return const EmptyWidget(message: '暂无通知', icon: Icons.notifications_none);
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: merged.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildNotificationCard(merged[index]),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final title = notif['title'] as String? ?? '';
    final content = notif['content'] as String? ?? '';
    final isRead = notif['isRead'] == true;
    final type = notif['type'] as String? ?? '';
    final createdAt = notif['createdAt'] as num?;

    return GestureDetector(
      onTap: () => _onTapNotification(notif),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(12),
          border: isRead ? null : Border.all(color: AppColors.primary.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _typeIcon(type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 13, color: AppColors.bodyText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.subtitle),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.subtitle),
          ],
        ),
      ),
    );
  }

  Widget _typeIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'REQUEST_SUBMITTED':
        icon = Icons.description_outlined;
        color = const Color(0xFF155DFC);
        break;
      case 'REQUEST_APPROVED':
        icon = Icons.check_circle_outline;
        color = const Color(0xFF00A63E);
        break;
      case 'REQUEST_REJECTED':
        icon = Icons.cancel_outlined;
        color = const Color(0xFFDC2626);
        break;
      case 'QUOTE_RECEIVED':
        icon = Icons.request_quote_outlined;
        color = const Color(0xFFD97706);
        break;
      case 'QUOTE_CONFIRMED':
        icon = Icons.handshake_outlined;
        color = const Color(0xFF00A63E);
        break;
      case 'ORDER_STATUS_CHANGED':
        icon = Icons.receipt_long_outlined;
        color = const Color(0xFF155DFC);
        break;
      case 'AFTERSALE_SUBMITTED':
        icon = Icons.support_agent;
        color = const Color(0xFFFF6B6B);
        break;
      case 'AFTERSALE_UPDATED':
        icon = Icons.update;
        color = const Color(0xFFFF6B6B);
        break;
      default:
        icon = Icons.notifications_outlined;
        color = AppColors.subtitle;
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  String _formatTime(num? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}-${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
