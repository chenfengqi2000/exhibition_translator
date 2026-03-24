import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/translator_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/state_widgets.dart';
import '../chat/chat_detail_page.dart';

class OpportunityDetailPage extends StatefulWidget {
  final int requestId;

  const OpportunityDetailPage({super.key, required this.requestId});

  @override
  State<OpportunityDetailPage> createState() => _OpportunityDetailPageState();
}

class _OpportunityDetailPageState extends State<OpportunityDetailPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = context.read<TranslatorService>();
      final result = await service.getOpportunityDetail(widget.requestId);
      if (mounted) setState(() { _data = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _navigateToQuotePage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QuoteFormPage(
          requestId: widget.requestId,
          displayData: _data,
        ),
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _openChatWithEmployer() async {
    final employerId = (_data?['employerId'] as num?)?.toInt();
    if (employerId == null) return;
    final employerName = _data?['contactName'] as String? ??
        _data?['companyName'] as String? ?? '雇主';
    try {
      final chatService = context.read<ChatService>();
      final conv = await chatService.getOrCreateConversation(employerId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(
              conversationId: (conv['id'] as num).toInt(),
              otherUserName: employerName,
              otherUserId: employerId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发起聊天失败: $e')),
        );
      }
    }
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
          '需求详情',
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
    if (_error != null) return ErrorRetryWidget(message: _error!, onRetry: _loadData);
    if (_data == null) return const EmptyWidget(message: '需求不存在');

    final d = _data!;
    final myQuote = d['myQuote'] as Map<String, dynamic>?;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroCard(d),
                const SizedBox(height: 12),
                _serviceInfoCard(d),
                const SizedBox(height: 12),
                _requirementsCard(d),
                const SizedBox(height: 12),
                _employerCard(d),
                if (myQuote != null) ...[
                  const SizedBox(height: 12),
                  _myQuoteCard(myQuote),
                ],
              ],
            ),
          ),
        ),
        _buildBottomBar(hasQuote: myQuote != null),
      ],
    );
  }

  // ── Hero card (Figma-aligned) ──────────────────────────────────────────────

  Widget _heroCard(Map<String, dynamic> d) {
    final budgetMin = (d['budgetMinAed'] as num?)?.toInt();
    final budgetMax = (d['budgetMaxAed'] as num?)?.toInt();
    final dateStart = d['dateStart'] as String? ?? '';
    final dateEnd = d['dateEnd'] as String? ?? '';
    final requestStatus = d['requestStatus'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A6CF7), Color(0xFF5B7CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  d['expoName'] ?? '',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (requestStatus.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _requestStatusLabel(requestStatus),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '连续服务',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '预算报价',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: Text(
                                (budgetMin != null && budgetMax != null)
                                    ? 'AED $budgetMin-$budgetMax'
                                    : '面议',
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (budgetMin != null)
                              const Text(
                                ' /天',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 13, color: Colors.white.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            '服务日期',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateRange(dateStart, dateEnd),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 展会与服务信息 card ────────────────────────────────────────────────────

  Widget _serviceInfoCard(Map<String, dynamic> d) {
    final city = d['city'] as String? ?? '';
    final venue = d['venue'] as String? ?? '';
    final languages = (d['languagePairs'] as List?)?.cast<String>().join(' / ') ?? '';
    final translationType = d['translationType'] as String? ?? '';
    final industry = d['industry'] as String? ?? '';

    return _sectionCard(
      title: '展会与服务信息',
      titleIcon: Icons.info_outline,
      children: [
        _iconInfoRow(
          icon: Icons.location_on_outlined,
          label: '展会地点',
          value: city,
          subValue: venue.isNotEmpty ? venue : null,
        ),
        if (languages.isNotEmpty) ...[
          const _CardDivider(),
          _iconInfoRow(
            icon: Icons.translate,
            label: '语言组合',
            value: languages,
          ),
        ],
        if (translationType.isNotEmpty) ...[
          const _CardDivider(),
          _iconInfoRow(
            icon: Icons.work_outline,
            label: '翻译类型',
            value: translationType,
            subValue: industry.isNotEmpty ? industry : null,
          ),
        ],
      ],
    );
  }

  // ── 服务要求 card ─────────────────────────────────────────────────────────

  Widget _requirementsCard(Map<String, dynamic> d) {
    final translationType = d['translationType'] as String? ?? '';
    final industry = d['industry'] as String? ?? '';
    final invoiceRequired = d['invoiceRequired'] as bool? ?? false;
    final remark = d['remark'] as String? ?? '';

    final chips = <_ChipData>[
      if (translationType.isNotEmpty) _ChipData(Icons.work_outline, translationType),
      if (industry.isNotEmpty) _ChipData(Icons.category_outlined, industry),
      if (invoiceRequired) _ChipData(Icons.receipt_long_outlined, '需要开票'),
    ];

    return _sectionCard(
      title: '服务要求',
      titleIcon: Icons.checklist_outlined,
      children: [
        if (chips.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((chip) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chip.icon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(chip.label, style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                ],
              ),
            )).toList(),
          ),
        if (remark.isNotEmpty) ...[
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
          ],
          const Text('补充说明', style: TextStyle(color: AppColors.subtitle, fontSize: 12)),
          const SizedBox(height: 4),
          Text(remark, style: const TextStyle(color: AppColors.bodyText, fontSize: 14)),
        ],
        if (chips.isEmpty && remark.isEmpty)
          const Text('暂无特殊要求', style: TextStyle(color: AppColors.subtitle, fontSize: 14)),
      ],
    );
  }

  // ── 服务发起方 card ───────────────────────────────────────────────────────

  Widget _employerCard(Map<String, dynamic> d) {
    final companyName = d['companyName'] as String? ?? '';
    final invoiceRequired = d['invoiceRequired'] as bool? ?? false;
    final hasOrder = d['hasOrder'] as bool? ?? false;
    final contactName = d['contactName'] as String? ?? '';
    final contactPhone = d['contactPhone'] as String? ?? '';

    return _sectionCard(
      title: '服务发起方',
      titleIcon: Icons.business_outlined,
      children: [
        if (companyName.isNotEmpty) ...[
          _labelValueRow(Icons.business_outlined, '公司名称', companyName),
          const _CardDivider(),
        ],
        _labelValueRow(
          Icons.receipt_long_outlined,
          '开票需求',
          invoiceRequired ? '需要开票' : '无需开票',
        ),
        const _CardDivider(),
        if (hasOrder && (contactName.isNotEmpty || contactPhone.isNotEmpty))
          _labelValueRow(
            Icons.person_outline,
            '联系方式',
            '${contactName.isNotEmpty ? contactName : ''}${contactName.isNotEmpty && contactPhone.isNotEmpty ? '  ' : ''}${contactPhone.isNotEmpty ? contactPhone : ''}'.trim(),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: AppColors.subtitle),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '订单确认后展示完整联系方式',
                    style: TextStyle(color: AppColors.subtitle, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── 我的报价 card ─────────────────────────────────────────────────────────

  Widget _myQuoteCard(Map<String, dynamic> quote) {
    final quoteType = quote['quoteType'] as String? ?? 'DAILY';
    final amountAed = quote['amountAed'];
    final serviceDays = quote['serviceDays'] ?? 1;
    final taxType = quote['taxType'] as String? ?? '';
    final quoteStatus = quote['quoteStatus'] as String? ?? '';
    final remark = quote['remark'] as String? ?? '';

    String quoteTypeLabel;
    switch (quoteType) {
      case 'HOURLY': quoteTypeLabel = '按时报价'; break;
      case 'PROJECT': quoteTypeLabel = '按项目报价'; break;
      default: quoteTypeLabel = '按天报价';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                '我的报价',
                style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _quoteStatusLabel(quoteStatus),
                  style: const TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'AED $amountAed',
            style: const TextStyle(color: AppColors.darkText, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$quoteTypeLabel · $serviceDays天 · ${taxType == 'TAX_INCLUDED' ? '含税' : '不含税'}',
            style: const TextStyle(color: AppColors.subtitle, fontSize: 13),
          ),
          if (remark.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('备注：$remark', style: const TextStyle(color: AppColors.bodyText, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    IconData? titleIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(titleIcon, size: 12, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(color: AppColors.darkText, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _iconInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.subtitle, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 2),
                Text(subValue, style: const TextStyle(color: AppColors.subtitle, fontSize: 12)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _labelValueRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.subtitle),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.subtitle, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar({bool hasQuote = false}) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _openChatWithEmployer,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('聊天沟通'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.darkText,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _navigateToQuotePage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: Text(hasQuote ? '修改报价' : '提交报价', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(String start, String end) {
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      final days = e.difference(s).inDays + 1;
      return '${s.month}月${s.day}日-${e.month}月${e.day}日($days天)';
    } catch (_) {
      return '$start ~ $end';
    }
  }

  String _requestStatusLabel(String status) {
    const map = {
      'OPEN': '招募中', 'CLOSED': '已关闭',
      'PENDING_REVIEW': '审核中', 'APPROVED': '已通过',
    };
    return map[status] ?? status;
  }

  String _quoteStatusLabel(String status) {
    const map = {
      'SUBMITTED': '已提交', 'ACCEPTED': '已选中',
      'REJECTED': '未选中', 'WITHDRAWN': '已撤回',
    };
    return map[status] ?? status;
  }
}

// ── Chip data helper ──────────────────────────────────────────────────────

class _ChipData {
  final IconData icon;
  final String label;
  const _ChipData(this.icon, this.label);
}

// ── Shared thin divider ────────────────────────────────────────────────────

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Color(0xFFF3F4F6)),
    );
  }
}


// ── Quote form page (Figma-aligned rewrite) ─────────────────────────────────

class _QuoteFormPage extends StatefulWidget {
  final int requestId;
  final Map<String, dynamic>? displayData;

  const _QuoteFormPage({
    required this.requestId,
    required this.displayData,
  });

  @override
  State<_QuoteFormPage> createState() => _QuoteFormPageState();
}

class _QuoteFormPageState extends State<_QuoteFormPage> {
  final _amountController = TextEditingController();
  final _quoteRemarkController = TextEditingController();
  final _extraRemarkController = TextEditingController();
  final _overtimeAmountController = TextEditingController();

  String _quoteType = 'DAILY';
  String _taxType = 'TAX_EXCLUDED';
  bool _submitting = false;
  bool _showSuccess = false;

  // Auto-prefilled from request data
  late String _dateStart;
  late String _dateEnd;
  late String _timeSlots;
  late int _serviceDays;

  // Overtime fee (Figma: 加时费用 card)
  bool _overtimeEnabled = false;
  String _overtimeBillingType = 'HALF_DAY'; // HALF_DAY or HOURLY

  @override
  void initState() {
    super.initState();
    _prefillFromRequest();
  }

  /// Pre-fill dates, service days, time slots from request data.
  /// e.g. dateStart=9/16, dateEnd=9/18 → serviceDays=3
  void _prefillFromRequest() {
    final d = widget.displayData;
    _dateStart = d?['dateStart'] as String? ?? '';
    _dateEnd = d?['dateEnd'] as String? ?? '';
    _serviceDays = _calculateDays(_dateStart, _dateEnd);

    // Pre-fill time slots from request or default to 09:00-17:00
    final existingSlots = d?['serviceTimeSlots'];
    if (existingSlots is List && existingSlots.isNotEmpty) {
      _timeSlots = existingSlots.first.toString();
    } else {
      _timeSlots = '09:00-17:00';
    }
  }

  int _calculateDays(String start, String end) {
    if (start.isEmpty || end.isEmpty) return 1;
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      final days = e.difference(s).inDays + 1;
      return days > 0 ? days : 1;
    } catch (_) {
      return 1;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _quoteRemarkController.dispose();
    _extraRemarkController.dispose();
    _overtimeAmountController.dispose();
    super.dispose();
  }

  /// Combine all remark fields into a single string for the API.
  /// Overtime fee info is appended since the API schema doesn't have dedicated fields.
  String _buildCombinedRemark() {
    final parts = <String>[];
    if (_quoteRemarkController.text.trim().isNotEmpty) {
      parts.add(_quoteRemarkController.text.trim());
    }
    if (_overtimeEnabled) {
      final label = _overtimeBillingType == 'HALF_DAY' ? '半天' : '小时';
      final amt = _overtimeAmountController.text.trim();
      if (amt.isNotEmpty) {
        parts.add('加时费用: AED $amt/$label');
      }
    }
    if (_extraRemarkController.text.trim().isNotEmpty) {
      parts.add('补充备注: ${_extraRemarkController.text.trim()}');
    }
    return parts.join('\n');
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效报价金额')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final service = context.read<TranslatorService>();
      await service.submitQuote({
        'requestId': widget.requestId,
        'quoteType': _quoteType,
        'amountAed': amount,
        'serviceDays': _serviceDays,
        'serviceTimeSlots': [_timeSlots],
        'taxType': _taxType,
        'remark': _buildCombinedRemark(),
      });

      if (mounted) {
        setState(() {
          _submitting = false;
          _showSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) return _buildSuccessPage();
    return _buildFormPage();
  }

  // ── 9. 提交成功状态页 ────────────────────────────────────────────────────

  Widget _buildSuccessPage() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A63E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 24),
                const Text(
                  '报价提交成功',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '您的报价已提交，雇主确认后将自动更新订单状态',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.subtitle, fontSize: 14),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                    child: const Text(
                      '查看订单',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.bodyText,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      '返回工作台',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Form page scaffold ──────────────────────────────────────────────────

  Widget _buildFormPage() {
    final d = widget.displayData;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        title: const Text(
          '提交报价',
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText, size: 20),
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
                  // Card 1: 需求摘要
                  if (d != null) _buildSummaryCard(d),
                  const SizedBox(height: 12),
                  // Card 2: 报价信息
                  _buildQuoteInfoCard(),
                  const SizedBox(height: 12),
                  // Card 3: 服务时段
                  _buildServiceTimeCard(),
                  const SizedBox(height: 12),
                  // Card 4: 报价说明
                  _buildQuoteRemarkCard(),
                  const SizedBox(height: 12),
                  // Card 5: 加时费用
                  _buildOvertimeCard(),
                  const SizedBox(height: 12),
                  // Card 6: 补充备注
                  _buildExtraRemarkCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Card 8: 底部固定提交按钮
          _buildBottomSubmitBar(),
        ],
      ),
    );
  }

  // ── Card 1: 需求摘要卡 ──────────────────────────────────────────────────

  Widget _buildSummaryCard(Map<String, dynamic> d) {
    final expoName = d['expoName'] as String? ?? '';
    final languages =
        (d['languagePairs'] as List?)?.cast<String>().join(' / ') ?? '';
    final translationType = d['translationType'] as String? ?? '';
    final budgetMin = (d['budgetMinAed'] as num?)?.toInt();
    final budgetMax = (d['budgetMaxAed'] as num?)?.toInt();

    final subtitleParts = <String>[
      if (_dateStart.isNotEmpty && _dateEnd.isNotEmpty)
        '$_dateStart ~ $_dateEnd',
      if (languages.isNotEmpty) languages,
      if (translationType.isNotEmpty) translationType,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            expoName,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitleParts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitleParts.join(' · '),
              style: const TextStyle(color: AppColors.subtitle, fontSize: 12),
            ),
          ],
          if (budgetMin != null && budgetMax != null) ...[
            const SizedBox(height: 4),
            Text(
              '客户预算: AED $budgetMin ~ $budgetMax/天',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Card 2: 报价信息卡 ──────────────────────────────────────────────────

  Widget _buildQuoteInfoCard() {
    String quoteTypeDisplay;
    switch (_quoteType) {
      case 'HOURLY':
        quoteTypeDisplay = '按时';
        break;
      case 'PROJECT':
        quoteTypeDisplay = '按项目';
        break;
      default:
        quoteTypeDisplay = '按天';
    }

    final amountText = _amountController.text.trim();
    String amountDisplay;
    if (amountText.isNotEmpty) {
      final suffix =
          _quoteType == 'DAILY' ? '/天' : (_quoteType == 'HOURLY' ? '/时' : '');
      amountDisplay = 'AED $amountText$suffix';
    } else {
      amountDisplay = '请输入';
    }

    return _whiteCard(children: [
      _cardTitle('报价信息'),
      const SizedBox(height: 8),
      _formRow(
          label: '报价方式',
          value: quoteTypeDisplay,
          onTap: _pickQuoteType,
          showDivider: true),
      _formRow(
          label: '报价金额',
          value: amountDisplay,
          valueColor: amountText.isEmpty ? AppColors.subtitle : null,
          onTap: _pickAmount,
          showDivider: true),
      _formRow(
          label: '含税说明',
          value: _taxType == 'TAX_INCLUDED' ? '含税' : '不含税',
          onTap: _pickTaxType,
          showDivider: true),
      _formRow(
          label: '可服务天数',
          value: '$_serviceDays天 (全程)',
          showDivider: false),
    ]);
  }

  // ── Card 3: 服务时段卡 ──────────────────────────────────────────────────

  Widget _buildServiceTimeCard() {
    return _whiteCard(children: [
      _cardTitle('服务时段'),
      const SizedBox(height: 8),
      _formRow(
          label: '开始日期',
          value: _dateStart.isNotEmpty ? _dateStart : '未设置',
          onTap: () => _pickDate(isStart: true),
          showDivider: true),
      _formRow(
          label: '结束日期',
          value: _dateEnd.isNotEmpty ? _dateEnd : '未设置',
          onTap: () => _pickDate(isStart: false),
          showDivider: true),
      _formRow(
          label: '每日时段',
          value: _timeSlots,
          onTap: _pickTimeSlots,
          showDivider: false),
    ]);
  }

  // ── Card 4: 报价说明卡 ──────────────────────────────────────────────────

  Widget _buildQuoteRemarkCard() {
    return _whiteCard(children: [
      _cardTitle('报价说明'),
      const SizedBox(height: 8),
      _textArea(
          controller: _quoteRemarkController,
          hint: '请描述您的报价说明、包含内容等...',
          height: 96),
    ]);
  }

  // ── Card 5: 加时费用卡 ──────────────────────────────────────────────────

  Widget _buildOvertimeCard() {
    final billingLabel = _overtimeBillingType == 'HALF_DAY' ? '半天' : '小时';

    return _whiteCard(children: [
      // Header: icon + title + subtitle + toggle
      Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.schedule, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('加时费用',
                    style: TextStyle(
                        color: AppColors.darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('可选项 · 如雇主临时需要加时服务',
                    style: TextStyle(color: Color(0xFFB0B8C9), fontSize: 11)),
              ],
            ),
          ),
          Switch.adaptive(
            value: _overtimeEnabled,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _overtimeEnabled = v),
          ),
        ],
      ),

      // Expandable content when toggle is ON
      if (_overtimeEnabled) ...[
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF9FAFB)),
        const SizedBox(height: 13),

        // 加时计费方式
        const Text('加时计费方式',
            style: TextStyle(color: AppColors.subtitle, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _billingTypeButton('按半天', 'HALF_DAY')),
            const SizedBox(width: 8),
            Expanded(child: _billingTypeButton('按小时', 'HOURLY')),
          ],
        ),
        const SizedBox(height: 12),

        // 加时费用输入
        Text('加时费用 ($billingLabel)',
            style: const TextStyle(color: AppColors.subtitle, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          height: 47,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text('AED',
                    style:
                        TextStyle(color: AppColors.subtitle, fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _overtimeAmountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: AppColors.darkText, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '请输入金额',
                    hintStyle:
                        TextStyle(color: Color(0x801E2A4A), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('/ $billingLabel',
                    style: const TextStyle(
                        color: Color(0xFFB0B8C9), fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Info tip box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.attach_money, size: 14, color: AppColors.subtitle),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '正常报价对应固定服务时段（每天8小时），如雇主临时要求加时，将按此标准额外收费',
                  style: TextStyle(
                      color: AppColors.subtitle,
                      fontSize: 11,
                      height: 1.625),
                ),
              ),
            ],
          ),
        ),
      ],
    ]);
  }

  Widget _billingTypeButton(String label, String type) {
    final selected = _overtimeBillingType == type;
    return GestureDetector(
      onTap: () => setState(() => _overtimeBillingType = type),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.bodyText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Card 6: 补充备注卡 ──────────────────────────────────────────────────

  Widget _buildExtraRemarkCard() {
    return _whiteCard(children: [
      _cardTitle('补充备注'),
      const SizedBox(height: 8),
      _textArea(
          controller: _extraRemarkController,
          hint: '其他需要补充的信息...',
          height: 64),
    ]);
  }

  // ── 8. 底部固定操作区 ────────────────────────────────────────────────────

  Widget _buildBottomSubmitBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 13,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 2,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('提交报价',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  // ── Shared widget helpers ───────────────────────────────────────────────

  Widget _whiteCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, 1)),
          BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 2,
              offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _cardTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.darkText,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _formRow({
    required String label,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
    required bool showDivider,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 46,
        decoration: showDivider
            ? const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Color(0xFFF9FAFB))))
            : null,
        child: Row(
          children: [
            Text(label,
                style:
                    const TextStyle(color: AppColors.bodyText, fontSize: 14)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.darkText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.subtitle),
            ],
          ],
        ),
      ),
    );
  }

  Widget _textArea({
    required TextEditingController controller,
    required String hint,
    double height = 96,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        style: const TextStyle(color: AppColors.darkText, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0x801E2A4A), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  // ── Pickers ─────────────────────────────────────────────────────────────

  void _pickQuoteType() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('选择报价方式',
                style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final e in {
              'DAILY': '按天',
              'HOURLY': '按时',
              'PROJECT': '按项目'
            }.entries)
              ListTile(
                title: Text(e.value),
                trailing: _quoteType == e.key
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _quoteType = e.key);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _pickAmount() {
    final ctrl = TextEditingController(text: _amountController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('输入报价金额'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: '请输入金额', prefixText: 'AED '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          TextButton(
            onPressed: () {
              setState(() => _amountController.text = ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _pickTaxType() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('选择含税说明',
                style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('含税'),
              trailing: _taxType == 'TAX_INCLUDED'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _taxType = 'TAX_INCLUDED');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('不含税'),
              trailing: _taxType == 'TAX_EXCLUDED'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _taxType = 'TAX_EXCLUDED');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial =
        DateTime.tryParse(isStart ? _dateStart : _dateEnd) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _dateStart = formatted;
        } else {
          _dateEnd = formatted;
        }
        _serviceDays = _calculateDays(_dateStart, _dateEnd);
      });
    }
  }

  void _pickTimeSlots() {
    final ctrl = TextEditingController(text: _timeSlots);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置每日时段'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '如 09:00-17:00'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          TextButton(
            onPressed: () {
              setState(() => _timeSlots = ctrl.text.trim().isNotEmpty
                  ? ctrl.text.trim()
                  : '09:00-17:00');
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
