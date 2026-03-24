import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class InvoiceDetailPage extends StatelessWidget {
  final Map<String, dynamic> invoice;

  const InvoiceDetailPage({super.key, required this.invoice});

  // Mock timeline data
  List<Map<String, String>> get _mockTimeline {
    final status = invoice['status'] as String;
    final list = <Map<String, String>>[
      {'title': '提交开票申请', 'time': '${invoice['date']} 10:30', 'desc': '已提交开票申请，等待处理'},
    ];
    if (status == 'processing' || status == 'completed') {
      list.add({'title': '开票处理中', 'time': '${invoice['date']} 14:00', 'desc': '财务已受理，正在开具发票'});
    }
    if (status == 'completed') {
      list.add({'title': '开票完成', 'time': '${invoice['date']} 16:30', 'desc': '发票已开具，可下载查看'});
    }
    return list.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Custom AppBar + Header
                SliverToBoxAdapter(child: _buildHeaderSection(context)),
                // Info card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildInfoCard(),
                  ),
                ),
                // Timeline card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: _buildTimelineCard(),
                  ),
                ),
              ],
            ),
          ),
          // Bottom button
          if (invoice['status'] == 'completed') _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // AppBar row
          SizedBox(
            height: 44,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    '发票详情',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Header content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              children: [
                Text(
                  invoice['id'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AED ${invoice['amount']}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    invoice['statusLabel'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '开票信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('发票抬头', invoice['title'] ?? ''),
          _buildDivider(),
          _buildDetailRow('税号', '91440300MA5FXXX'),
          _buildDivider(),
          _buildDetailRow('发票类型', '增值税普通发票'),
          _buildDivider(),
          _buildDetailRow('发票内容', '翻译服务费'),
          _buildDivider(),
          _buildDetailRow('接收邮箱', 'finance@example.com'),
          _buildDivider(),
          _buildDetailRow('关联订单', invoice['orderId'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.subtitle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: AppColors.darkText),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.border);
  }

  Widget _buildTimelineCard() {
    final timeline = _mockTimeline;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '处理记录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(timeline.length, (index) {
            final item = timeline[index];
            final isFirst = index == 0;
            final isLast = index == timeline.length - 1;
            return _buildTimelineNode(
              title: item['title'] ?? '',
              time: item['time'] ?? '',
              desc: item['desc'] ?? '',
              isFirst: isFirst,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required String title,
    required String time,
    required String desc,
    required bool isFirst,
    required bool isLast,
  }) {
    final dotColor = isFirst ? AppColors.primary : AppColors.subtitle.withOpacity(0.4);
    final lineColor = AppColors.subtitle.withOpacity(0.2);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isFirst ? FontWeight.w600 : FontWeight.normal,
                      color: isFirst ? AppColors.darkText : AppColors.bodyText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('发票下载功能开发中')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: const Text(
            '下载发票',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
