import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/aftersales_service.dart';
import '../../config/api_config.dart';

class AftersalesDetailPage extends StatefulWidget {
  final int aftersaleId;

  const AftersalesDetailPage({super.key, required this.aftersaleId});

  @override
  State<AftersalesDetailPage> createState() => _AftersalesDetailPageState();
}

class _AftersalesDetailPageState extends State<AftersalesDetailPage> {
  Map<String, dynamic>? _record;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = context.read<AftersalesService>();
      final data = await service.getAftersale(widget.aftersaleId);
      if (mounted) setState(() { _record = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
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

  List<Map<String, String>> _buildTimeline(Map<String, dynamic> r) {
    final status = r['status'] as String? ?? 'processing';
    final createdTs = r['createdAt'];
    final submittedAt = _formatTs(createdTs);
    final list = <Map<String, String>>[
      {'title': '投诉提交', 'desc': '您提交了售后/投诉申请', 'time': submittedAt},
    ];
    if (status == 'processing' || status == 'resolved' || status == 'closed') {
      list.add({'title': '平台受理', 'desc': '客服已受理您的投诉', 'time': _addMinutes(createdTs, 30)});
    }
    if (status == 'resolved' || status == 'closed') {
      list.add({'title': '处理完成', 'desc': '投诉已处理完成', 'time': _formatTs(r['updatedAt'])});
    } else {
      list.add({'title': '处理完成', 'desc': '等待平台处理', 'time': ''});
    }
    return list.reversed.toList();
  }

  String _addMinutes(dynamic ts, int minutes) {
    if (ts == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch((ts as int) * 1000)
        .add(Duration(minutes: minutes));
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('售后详情'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.darkText,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.subtitle)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final r = _record!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, r)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildInfoCard(context, r),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _buildTimelineCard(r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> r) {
    final topPadding = MediaQuery.of(context).padding.top;
    final status = r['status'] as String? ?? 'processing';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: Color(0xFFFF6B6B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
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
                    '售后详情',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                Text(
                  'AS-${r['id'].toString().padLeft(6, '0')}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 6),
                Text(
                  r['type'] ?? '售后投诉',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel(status),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Map<String, dynamic> r) {
    final images = List<String>.from(r['evidenceImages'] ?? []);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('投诉信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText)),
          const SizedBox(height: 16),
          _detailRow('关联订单', 'ORD-${r['orderId'].toString().padLeft(6, '0')}'),
          const Divider(height: 1, color: Color(0xFFF9FAFB)),
          _detailRow('问题类型', r['type'] ?? ''),
          const Divider(height: 1, color: Color(0xFFF9FAFB)),
          _detailRow('提交时间', _formatTs(r['createdAt'])),
          const Divider(height: 1, color: Color(0xFFF9FAFB)),
          const SizedBox(height: 13),
          const Text('问题描述', style: TextStyle(fontSize: 13, color: AppColors.subtitle)),
          const SizedBox(height: 6),
          Text(
            r['description'] as String? ?? '无描述',
            style: const TextStyle(fontSize: 14, color: AppColors.darkText, height: 1.5),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('上传凭证', style: TextStyle(fontSize: 13, color: AppColors.subtitle)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: images.map<Widget>((url) {
                final fullUrl = url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
                return GestureDetector(
                  onTap: () => _showFullNetworkImage(context, fullUrl),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.network(
                        fullUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, size: 24, color: AppColors.subtitle),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullNetworkImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.subtitle)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText)),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(Map<String, dynamic> r) {
    final timeline = _buildTimeline(r);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('处理时间线', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText)),
          const SizedBox(height: 16),
          ...List.generate(timeline.length, (index) {
            final item = timeline[index];
            final isLast = index == timeline.length - 1;
            final isCompleted = (item['time'] ?? '').isNotEmpty;
            return _timelineNode(
              title: item['title'] ?? '',
              desc: item['desc'] ?? '',
              time: item['time'] ?? '',
              isLast: isLast,
              isCompleted: isCompleted,
            );
          }),
        ],
      ),
    );
  }

  Widget _timelineNode({
    required String title,
    required String desc,
    required String time,
    required bool isLast,
    required bool isCompleted,
  }) {
    final dotColor = isCompleted ? AppColors.primary : const Color(0xFFC0C0C0);
    final lineColor = isCompleted ? AppColors.primary : const Color(0xFFE5E7EB);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? dotColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: isCompleted ? 0 : 2),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 1.5, color: lineColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
                      fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
                      color: isCompleted ? AppColors.darkText : const Color(0xFFC0C0C0),
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.subtitle)),
                  ],
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFFB0B8C9))),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
