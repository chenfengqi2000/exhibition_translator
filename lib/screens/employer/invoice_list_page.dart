import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'invoice_detail_page.dart';
import 'invoice_info_page.dart';

class InvoiceListPage extends StatelessWidget {
  const InvoiceListPage({super.key});

  // Mock data
  static final List<Map<String, dynamic>> _mockInvoices = [
    {
      'id': 'INV-20260301-001',
      'status': 'completed',
      'statusLabel': '已开票',
      'orderId': 'ORD-20260228-015',
      'title': '迪拜环球贸易有限公司',
      'amount': '3,500.00',
      'date': '2026-03-01',
    },
    {
      'id': 'INV-20260315-002',
      'status': 'processing',
      'statusLabel': '开票中',
      'orderId': 'ORD-20260310-022',
      'title': '迪拜环球贸易有限公司',
      'amount': '2,800.00',
      'date': '2026-03-15',
    },
    {
      'id': 'INV-20260320-003',
      'status': 'pending',
      'statusLabel': '待申请',
      'orderId': 'ORD-20260318-031',
      'title': '深圳前海科技有限公司',
      'amount': '5,200.00',
      'date': '2026-03-20',
    },
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF00A63E);
      case 'processing':
        return AppColors.primary;
      default:
        return AppColors.subtitle;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'processing':
        return const Color(0xFFDBEAFE);
      default:
        return const Color(0xFFF3F4F6);
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
          '我的发票',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvoiceInfoPage()),
              );
            },
            child: const Text(
              '开票信息',
              style: TextStyle(fontSize: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: _mockInvoices.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mockInvoices.length,
              itemBuilder: (context, index) => _buildInvoiceCard(context, _mockInvoices[index]),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.subtitle.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('暂无发票记录', style: TextStyle(fontSize: 15, color: AppColors.subtitle)),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Map<String, dynamic> invoice) {
    final status = invoice['status'] as String;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InvoiceDetailPage(invoice: invoice)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: INV number + status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    invoice['id'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBgColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    invoice['statusLabel'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            // Info rows
            _buildInfoRow('关联订单', invoice['orderId']),
            const SizedBox(height: 10),
            _buildInfoRow('开票抬头', invoice['title']),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  '金额',
                  style: TextStyle(fontSize: 13, color: AppColors.subtitle),
                ),
                const Spacer(),
                Text(
                  'AED ${invoice['amount']}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.darkText),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
