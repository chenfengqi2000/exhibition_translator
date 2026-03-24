import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/employer_service.dart';
import '../../widgets/state_widgets.dart';
import '../common/order_detail_page.dart';

class EmployerRequestsPage extends StatefulWidget {
  const EmployerRequestsPage({super.key});

  @override
  State<EmployerRequestsPage> createState() => EmployerRequestsPageState();
}

class EmployerRequestsPageState extends State<EmployerRequestsPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void reload() => _loadRequests();

  Future<void> _loadRequests() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = context.read<EmployerService>();
      final result = await service.listRequests();
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(result['list'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('我的需求', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return ErrorRetryWidget(message: _error!, onRetry: _loadRequests);
    if (_requests.isEmpty) {
      return const EmptyWidget(message: '暂无需求，快去发布一个吧', icon: Icons.inbox_outlined);
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final status = req['requestStatus'] ?? '';
    final reviewStatus = req['reviewStatus'] ?? 'PENDING_REVIEW';
    final quoteCount = req['quoteCount'] ?? 0;
    final hasOrder = req['hasOrder'] == true;
    final orderId = req['orderId'];

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(requestId: req['id'] as int, isEmployer: true),
          ),
        );
        _loadRequests();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    req['expoName'] ?? '',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _statusBadge(status),
              ],
            ),
            if (reviewStatus != 'APPROVED') ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  _reviewStatusBadge(reviewStatus),
                  if (reviewStatus == 'PENDING_REVIEW') ...[
                    const SizedBox(width: 8),
                    _devApproveButton(req['id'] as int),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 10),
            _infoRow(Icons.location_on_outlined, '${req['city']} · ${req['venue'] ?? ''}'),
            const SizedBox(height: 6),
            _infoRow(Icons.calendar_today_outlined, req['dateRange'] ?? ''),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: quoteCount > 0 ? const Color(0xFFDBEAFE) : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '收到 $quoteCount 条报价',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: quoteCount > 0 ? const Color(0xFF155DFC) : AppColors.subtitle,
                    ),
                  ),
                ),
                const Spacer(),
                if (hasOrder && orderId != null)
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailPage(orderId: orderId as int, isEmployer: true),
                        ),
                      );
                      _loadRequests();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long, size: 14, color: Color(0xFF00A63E)),
                          SizedBox(width: 4),
                          Text('查看订单', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF00A63E))),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.subtitle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'OPEN':
        bg = const Color(0xFFDBEAFE); fg = const Color(0xFF155DFC); label = '开放中';
        break;
      case 'QUOTING':
        bg = const Color(0xFFFFF7ED); fg = const Color(0xFFD97706); label = '报价中';
        break;
      case 'CLOSED':
        bg = const Color(0xFFDCFCE7); fg = const Color(0xFF00A63E); label = '已关闭';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626); label = '已取消';
        break;
      default:
        bg = AppColors.background; fg = AppColors.subtitle; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
    );
  }

  Widget _reviewStatusBadge(String reviewStatus) {
    Color bg;
    Color fg;
    IconData icon;
    String label;
    switch (reviewStatus) {
      case 'PENDING_REVIEW':
        bg = const Color(0xFFFFF7ED); fg = const Color(0xFFD97706);
        icon = Icons.hourglass_top; label = '审核中';
        break;
      case 'REJECTED':
        bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626);
        icon = Icons.cancel_outlined; label = '审核未通过';
        break;
      default:
        bg = const Color(0xFFDCFCE7); fg = const Color(0xFF00A63E);
        icon = Icons.check_circle_outline; label = '审核通过';
    }
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _devApproveButton(int requestId) {
    return GestureDetector(
      onTap: () async {
        try {
          final service = context.read<EmployerService>();
          await service.devApproveRequest(requestId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('需求审核已模拟通过'), backgroundColor: Color(0xFF00A63E)),
            );
            _loadRequests();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.redAccent),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.developer_mode, size: 12, color: AppColors.primary),
            SizedBox(width: 3),
            Text('[DEV] 模拟审核通过', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.subtitle),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.subtitle), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
