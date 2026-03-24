import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/review_service.dart';

class SubmitReviewPage extends StatefulWidget {
  final int orderId;
  final String translatorName;
  final String? translatorAvatar;
  final String? orderNo;
  final String? expoName;
  final String? dateRange;
  final String? serviceType;

  const SubmitReviewPage({
    super.key,
    required this.orderId,
    required this.translatorName,
    this.translatorAvatar,
    this.orderNo,
    this.expoName,
    this.dateRange,
    this.serviceType,
  });

  @override
  State<SubmitReviewPage> createState() => _SubmitReviewPageState();
}

class _SubmitReviewPageState extends State<SubmitReviewPage> {
  int _rating = 0;
  final _contentCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool? _willingToCooperate;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择评分')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final service = context.read<ReviewService>();
      await service.submitReview(
        orderId: widget.orderId,
        rating: _rating,
        content: _contentCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评价提交成功'), backgroundColor: Color(0xFF00A63E)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  String _ratingLabel(int rating) {
    const labels = {1: '非常差', 2: '较差', 3: '一般', 4: '满意', 5: '非常满意'};
    return labels[rating] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        title: const Text(
          '服务评价',
          style: TextStyle(color: AppColors.darkText, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  _buildTranslatorCard(),
                  const SizedBox(height: 12),
                  _buildRatingCard(),
                  const SizedBox(height: 12),
                  _buildTextCard(),
                  const SizedBox(height: 12),
                  _buildCooperationCard(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTranslatorCard() {
    final orderNo = widget.orderNo ?? 'ORD-${widget.orderId.toString().padLeft(6, '0')}';
    final expoName = widget.expoName ?? '';
    return Container(
      width: double.infinity,
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
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF9FAFB), width: 1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.background,
                  backgroundImage: widget.translatorAvatar != null && widget.translatorAvatar!.isNotEmpty
                      ? NetworkImage(widget.translatorAvatar!)
                      : null,
                  child: widget.translatorAvatar == null || widget.translatorAvatar!.isEmpty
                      ? const Icon(Icons.person, color: AppColors.subtitle, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.translatorName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$orderNo · $expoName',
                        style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.dateRange != null && widget.dateRange!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '服务日期：${widget.dateRange}',
              style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
          ],
          if (widget.serviceType != null && widget.serviceType!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '服务类型：${widget.serviceType}',
              style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      width: double.infinity,
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
          const Text(
            '服务评分',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: starIndex <= _rating ? const Color(0xFFFBBF24) : const Color(0xFFD1D5DB),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _rating == 0 ? '点击选择评分' : _ratingLabel(_rating),
              style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard() {
    return Container(
      width: double.infinity,
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
          const Text(
            '文字评价',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentCtrl,
            maxLines: 5,
            maxLength: 200,
            style: const TextStyle(fontSize: 14, color: AppColors.darkText),
            decoration: InputDecoration(
              hintText: '请分享您对本次翻译服务的评价...',
              hintStyle: TextStyle(fontSize: 14, color: AppColors.darkText.withOpacity(0.5)),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCooperationCard() {
    return Container(
      width: double.infinity,
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
          const Text(
            '是否愿意再次合作？',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _cooperationButton('愿意', true)),
              const SizedBox(width: 12),
              Expanded(child: _cooperationButton('不愿意', false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cooperationButton(String label, bool value) {
    final isSelected = _willingToCooperate == value;
    return GestureDetector(
      onTap: () => setState(() => _willingToCooperate = value),
      child: Container(
        height: 47,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.bodyText,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 13, 16, MediaQuery.of(context).padding.bottom + 13),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            elevation: 0,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('提交评价', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
