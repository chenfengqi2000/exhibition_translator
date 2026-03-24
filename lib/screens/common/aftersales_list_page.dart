import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/aftersales_provider.dart';
import 'aftersales_detail_page.dart';
import 'aftersales_complaint_page.dart';

class AftersalesListPage extends StatefulWidget {
  const AftersalesListPage({super.key});

  @override
  State<AftersalesListPage> createState() => _AftersalesListPageState();
}

class _AftersalesListPageState extends State<AftersalesListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AftersalesProvider>().loadAftersales();
    });
  }

  String _formatTs(dynamic ts) {
    if (ts == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch((ts as int) * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(String status) {
    const map = {'processing': '处理中', 'resolved': '已解决', 'closed': '已关闭'};
    return map[status] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('售后记录', style: TextStyle(color: AppColors.darkText, fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AftersalesComplaintPage()),
              );
              if (mounted) context.read<AftersalesProvider>().loadAftersales();
            },
            child: const Text('新建投诉', style: TextStyle(color: AppColors.primary, fontSize: 14)),
          ),
        ],
      ),
      body: Consumer<AftersalesProvider>(
        builder: (context, provider, _) {
          final records = provider.records;
          if (records.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadAftersales(),
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.support_agent, size: 64, color: AppColors.subtitle.withOpacity(0.25)),
                          const SizedBox(height: 16),
                          const Text('暂无售后记录', style: TextStyle(fontSize: 16, color: AppColors.subtitle)),
                          const SizedBox(height: 6),
                          const Text('如遇服务问题，可点击右上角新建投诉', style: TextStyle(fontSize: 13, color: AppColors.subtitle)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadAftersales(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: records.length,
              itemBuilder: (context, index) => _buildCard(context, records[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> record) {
    final status = record['status'] as String? ?? 'processing';
    final isResolved = status == 'resolved' || status == 'closed';
    final statusLabel = _statusLabel(status);
    final id = record['id'] as int?;

    return GestureDetector(
      onTap: id == null ? null : () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AftersalesDetailPage(aftersaleId: id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AS-${id.toString().padLeft(6, '0')}',
                    style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isResolved ? const Color(0xFFDCFCE7) : const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isResolved ? const Color(0xFF166534) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              record['type'] as String? ?? '',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 13, color: AppColors.subtitle),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'ORD-${record['orderId'].toString().padLeft(6, '0')}',
                    style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatTs(record['createdAt']),
                  style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('查看进度', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
