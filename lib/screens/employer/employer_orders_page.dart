import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/employer_service.dart';
import '../../widgets/state_widgets.dart';
import '../common/order_detail_page.dart';

class EmployerOrdersPage extends StatefulWidget {
  const EmployerOrdersPage({super.key});

  @override
  State<EmployerOrdersPage> createState() => _EmployerOrdersPageState();
}

class _EmployerOrdersPageState extends State<EmployerOrdersPage> {
  int _selectedTab = 0;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;

  static const _tabs = ['全部', 'PENDING_CONFIRM', 'CONFIRMED', 'IN_SERVICE', 'COMPLETED', 'CANCELLED'];
  static const _tabLabels = ['全部', '待确认', '已确认', '服务中', '已完成', '已取消'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = context.read<EmployerService>();
      final status = _selectedTab == 0 ? null : _tabs[_selectedTab];
      final result = await service.listOrders(status: status);
      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(result['list'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _statusLabel(String status) {
    const map = {
      'PENDING_QUOTE': '待报价', 'PENDING_CONFIRM': '待确认',
      'CONFIRMED': '已确认', 'IN_SERVICE': '服务中',
      'COMPLETED': '已完成', 'CANCELLED': '已取消',
    };
    return map[status] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 16, right: 16, bottom: 12),
            child: const Text('我的订单', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = _selectedTab == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = index);
                        _loadOrders();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _tabLabels[index],
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.white : AppColors.subtitle,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget(message: '加载中...');
    if (_error != null) return ErrorRetryWidget(message: _error!, onRetry: _loadOrders);
    if (_orders.isEmpty) return const EmptyWidget(message: '暂无订单');

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? '';
    final orderNo = order['orderNo'] ?? 'ORD-${(order['id'] ?? 0).toString().padLeft(6, '0')}';
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(orderId: order['id'] as int, isEmployer: true),
          ),
        );
        _loadOrders();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          children: [
            // Blue header strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderNo,
                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          order['expoName'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row(Icons.person_outline, '对方: ${order['counterpartName'] ?? ''}'),
                  const SizedBox(height: 8),
                  _row(Icons.calendar_today_outlined, order['dateRange'] ?? ''),
                  const SizedBox(height: 8),
                  _row(Icons.location_on_outlined, '${order['city'] ?? ''} · ${order['venue'] ?? ''}'),
                  if ((order['quoteSummary'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('总价', style: TextStyle(color: AppColors.subtitle, fontSize: 13)),
                        const Spacer(),
                        Text(order['quoteSummary'], style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if ((order['quoteBreakdown'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          order['quoteBreakdown'],
                          style: const TextStyle(color: AppColors.subtitle, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.subtitle),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.bodyText, fontSize: 13), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
