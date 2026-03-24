import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/review_service.dart';
import '../../widgets/state_widgets.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  List<Map<String, dynamic>> _reviews = [];
  int _total = 0;
  double _avgRating = 0.0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = context.read<ReviewService>();
      final result = await service.listMyReviews(pageSize: 50);
      if (mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(result['list'] ?? []);
          _total = (result['total'] as num?)?.toInt() ?? 0;
          _avgRating = (result['avgRating'] as num?)?.toDouble() ?? 0.0;
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
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '评价中心',
          style: TextStyle(color: AppColors.darkText, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget(message: '加载中...');
    if (_error != null) return ErrorRetryWidget(message: _error!, onRetry: _loadReviews);

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          Text('全部评价 ($_total)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText)),
          const SizedBox(height: 12),
          if (_reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Center(
                child: Text('暂无评价', style: TextStyle(color: AppColors.subtitle, fontSize: 14)),
              ),
            )
          else
            ..._reviews.map(_buildReviewCard),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                _avgRating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.darkText),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    (i + 1) <= _avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 18,
                    color: (i + 1) <= _avgRating.round() ? const Color(0xFFFBBF24) : AppColors.border,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('共 $_total 条评价', style: const TextStyle(fontSize: 14, color: AppColors.subtitle)),
              const SizedBox(height: 4),
              const Text('来自已完成订单的雇主评价', style: TextStyle(fontSize: 12, color: AppColors.subtitle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final content = review['content'] as String? ?? '';
    final employerName = review['employerName'] as String? ?? '雇主';
    final expoName = review['expoName'] as String? ?? '';
    final createdAt = review['createdAt'] as int?;

    String dateStr = '';
    if (createdAt != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
      dateStr = '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.background,
                child: Icon(Icons.person, size: 18, color: AppColors.subtitle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employerName.isNotEmpty ? employerName : '雇主',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText),
                    ),
                    if (expoName.isNotEmpty)
                      Text(expoName, style: const TextStyle(fontSize: 12, color: AppColors.subtitle)),
                  ],
                ),
              ),
              Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.subtitle)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                (i + 1) <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 18,
                color: (i + 1) <= rating ? const Color(0xFFFBBF24) : AppColors.border,
              );
            }),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 14, color: AppColors.bodyText)),
          ],
        ],
      ),
    );
  }
}
