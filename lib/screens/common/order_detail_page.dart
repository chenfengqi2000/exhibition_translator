import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/employer_service.dart';
import '../../services/translator_service.dart';
import '../../widgets/state_widgets.dart';
import '../../providers/aftersales_provider.dart';
import '../employer/submit_review_page.dart';
import 'aftersales_complaint_page.dart';
import 'aftersales_detail_page.dart';

/// 订单详情页 — 支持 3 种模式:
/// 1. 雇主查看需求详情 (requestId): 显示需求 + 报价列表 + 确认报价
/// 2. 雇主查看订单详情 (orderId + isEmployer=true): 显示订单 + 时间线
/// 3. 翻译员查看订单详情 (orderId + isEmployer=false): 显示订单 + 时间线 + 操作按钮
class OrderDetailPage extends StatefulWidget {
  final int? requestId;
  final int? orderId;
  final bool isEmployer;

  const OrderDetailPage({
    super.key,
    this.requestId,
    this.orderId,
    required this.isEmployer,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;
  bool _actionLoading = false;

  bool get _isRequestMode => widget.requestId != null && widget.orderId == null;

  @override
  void initState() {
    super.initState();
    _loadData();
    // 加载售后缓存，确保售后入口显示正确状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.orderId != null) {
        context.read<AftersalesProvider>().ensureLoaded();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      Map<String, dynamic> result;
      if (_isRequestMode) {
        final service = context.read<EmployerService>();
        result = await service.getRequestDetail(widget.requestId!);
      } else if (widget.isEmployer) {
        final service = context.read<EmployerService>();
        result = await service.getOrderDetail(widget.orderId!);
      } else {
        final service = context.read<TranslatorService>();
        result = await service.getOrderDetail(widget.orderId!);
      }
      if (mounted) setState(() { _data = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isRequestMode ? '需求详情' : '订单详情';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(title, style: const TextStyle(color: AppColors.darkText, fontSize: 17, fontWeight: FontWeight.w600)),
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
    if (_data == null) return const EmptyWidget(message: '数据不存在');

    if (_isRequestMode) return _buildRequestBody();
    return _buildOrderBody();
  }

  // ═══ 模式1: 雇主查看需求详情 + 报价列表 ═══
  Widget _buildRequestBody() {
    final d = _data!;
    final quotes = List<Map<String, dynamic>>.from(d['quotes'] ?? []);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _requestHeroCard(d),
            const SizedBox(height: 12),
            _requestServiceCard(d),
            const SizedBox(height: 12),
            _requestDetailCard(d),
            if (d['hasOrder'] == true && d['orderId'] != null) ...[
              const SizedBox(height: 12),
              _orderLinkCard(d['orderId'] as int),
            ],
            const SizedBox(height: 16),
            _quotesSection(quotes, d['id'] as int),
          ],
        ),
      ),
    );
  }

  Widget _requestHeroCard(Map<String, dynamic> d) {
    final statusLabel = _requestStatusLabel(d['requestStatus'] ?? '');
    final budgetMin = (d['budgetMinAed'] as num?)?.toInt();
    final budgetMax = (d['budgetMaxAed'] as num?)?.toInt();
    final dateStart = d['dateStart'] as String? ?? '';
    final dateEnd = d['dateEnd'] as String? ?? '';

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
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
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
                        Text('预算报价', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
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
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (budgetMin != null)
                              const Text(' /天', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                          Text('服务日期', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRequestDateRange(dateStart, dateEnd),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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

  Widget _requestServiceCard(Map<String, dynamic> d) {
    final city = d['city'] as String? ?? '';
    final venue = d['venue'] as String? ?? '';
    final languages = (d['languagePairs'] as List?)?.join(' / ') ?? '';
    final translationType = d['translationType'] as String? ?? '';
    final industry = d['industry'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.info_outline, size: 12, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Text('展会与服务信息', style: TextStyle(color: AppColors.darkText, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          _requestIconRow(Icons.location_on_outlined, '展会地点', city, subValue: venue.isNotEmpty ? venue : null),
          if (languages.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Color(0xFFF3F4F6))),
            _requestIconRow(Icons.translate, '语言组合', languages),
          ],
          if (translationType.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Color(0xFFF3F4F6))),
            _requestIconRow(Icons.work_outline, '翻译类型', translationType, subValue: industry.isNotEmpty ? industry : null),
          ],
        ],
      ),
    );
  }

  Widget _requestDetailCard(Map<String, dynamic> d) {
    final companyName = d['companyName'] as String? ?? '';
    final contactName = d['contactName'] as String? ?? '';
    final contactPhone = d['contactPhone'] as String? ?? '';
    final invoiceRequired = d['invoiceRequired'] as bool? ?? false;
    final remark = (d['remark'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.business_outlined, size: 12, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Text('其他信息', style: TextStyle(color: AppColors.darkText, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          if (companyName.isNotEmpty) ...[
            _labelValueRow('公司名称', companyName),
            const Divider(height: 1, color: Color(0xFFF9FAFB)),
          ],
          if (contactName.isNotEmpty || contactPhone.isNotEmpty) ...[
            _labelValueRow('联系人', '$contactName $contactPhone'.trim()),
            const Divider(height: 1, color: Color(0xFFF9FAFB)),
          ],
          _labelValueRow('开票需求', invoiceRequired ? '需要开票' : '无需开票'),
          if (remark.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF9FAFB)),
            const SizedBox(height: 12),
            const Text('补充备注', style: TextStyle(color: AppColors.subtitle, fontSize: 12)),
            const SizedBox(height: 4),
            Text(remark, style: const TextStyle(color: AppColors.bodyText, fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _requestIconRow(IconData icon, String label, String value, {String? subValue}) {
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
              Text(value, style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w500)),
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

  Widget _orderLinkCard(int orderId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(orderId: orderId, isEmployer: true),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00A63E).withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.receipt_long, color: Color(0xFF00A63E), size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('已生成订单', style: TextStyle(color: Color(0xFF00A63E), fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('此需求已确认报价并生成订单，点击查看订单进度', style: TextStyle(color: Color(0xFF166534), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Color(0xFF00A63E), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _quotesSection(List<Map<String, dynamic>> quotes, int requestId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('收到的报价 (${quotes.length})', style: const TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (quotes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Text('暂无报价，请等待翻译员响应', textAlign: TextAlign.center, style: TextStyle(color: AppColors.subtitle, fontSize: 14)),
          )
        else
          ...quotes.map((q) => _quoteCard(q, requestId)),
      ],
    );
  }

  Widget _quoteCard(Map<String, dynamic> q, int requestId) {
    final quoteStatus = q['quoteStatus'] ?? '';
    final isSubmitted = quoteStatus == 'SUBMITTED';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSubmitted ? AppColors.primary.withOpacity(0.3) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'AED ${q['amountAed']}',
                  style: const TextStyle(color: AppColors.darkText, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                _quoteStatusLabel(quoteStatus),
                style: TextStyle(color: isSubmitted ? AppColors.primary : AppColors.subtitle, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_quoteTypeLabel(q['quoteType'] ?? '')} · ${q['serviceDays'] ?? '-'}天',
            style: const TextStyle(color: AppColors.subtitle, fontSize: 13),
          ),
          if ((q['taxType'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(q['taxType'] == 'TAX_INCLUDED' ? '含税' : '不含税', style: const TextStyle(color: AppColors.subtitle, fontSize: 13)),
          ],
          if ((q['remark'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('备注: ${q['remark']}', style: const TextStyle(color: AppColors.bodyText, fontSize: 13)),
          ],
          if (isSubmitted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: _actionLoading ? null : () => _confirmQuote(requestId, q['id'] as int),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _actionLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('确认此报价', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmQuote(int requestId, int quoteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认报价'),
        content: const Text('确认后将创建订单，其他报价将被拒绝。是否继续？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _actionLoading = true);
    try {
      final service = context.read<EmployerService>();
      await service.confirmQuote(requestId, quoteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('报价确认成功，订单已创建')));
        _loadData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
    if (mounted) setState(() => _actionLoading = false);
  }

  // ═══ 模式2 & 3: 订单详情 (雇主/翻译员) ═══
  Widget _buildOrderBody() {
    final d = _data!;
    final request = d['request'] as Map<String, dynamic>?;
    final quote = d['quote'] as Map<String, dynamic>?;
    final timelines = List<Map<String, dynamic>>.from(d['timelines'] ?? []);
    final orderStatus = d['orderStatus'] ?? '';
    final confirmedArrivalAt = d['confirmedArrivalAt'] as int?;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _orderHeaderBanner(orderStatus, request),
                  const SizedBox(height: 12),
                  if (request != null) ...[
                    _orderExpoCard(request),
                    const SizedBox(height: 12),
                    _orderContactCard(request),
                  ],
                  if (quote != null) ...[
                    const SizedBox(height: 12),
                    _orderPriceCard(quote),
                  ],
                  const SizedBox(height: 12),
                  _orderCounterpartCard(d),
                  const SizedBox(height: 12),
                  _orderTimelineCard(timelines, orderStatus),
                  // After-sales entry (for employer, on completed/in-service orders)
                  if (widget.isEmployer && (orderStatus == 'COMPLETED' || orderStatus == 'IN_SERVICE' || orderStatus == 'PENDING_EMPLOYER_CONFIRMATION')) ...[
                    const SizedBox(height: 16),
                    _afterSalesEntry(),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
        if (!widget.isEmployer) _buildTranslatorActions(orderStatus, confirmedArrivalAt),
        if (widget.isEmployer) _buildEmployerActions(orderStatus),
      ],
    );
  }

  // ── After-sales entry card ──
  Widget _afterSalesEntry() {
    final orderId = widget.orderId;
    final existingRecord = orderId != null
        ? context.watch<AftersalesProvider>().findByOrderId(orderId)
        : null;
    final hasAftersales = existingRecord != null;
    final existingId = existingRecord?['id'] as int?;

    return GestureDetector(
      onTap: () {
        if (hasAftersales && existingId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AftersalesDetailPage(aftersaleId: existingId)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AftersalesComplaintPage(order: _data)),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE0E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.support_agent, color: Color(0xFFFF6B6B), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAftersales ? '查看售后进度' : '申请售后',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasAftersales ? '您已提交售后申请，点击查看处理进度' : '如遇问题，可提交售后投诉申请',
                    style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.subtitle, size: 20),
          ],
        ),
      ),
    );
  }

  // ── 1. Figma blue header banner ──
  Widget _orderHeaderBanner(String status, Map<String, dynamic>? request) {
    final orderNo = _data!['orderNo'] as String? ?? 'ORD-${(_data!['id'] as int).toString().padLeft(6, '0')}';
    final expoName = request?['expoName'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderNo,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  expoName.isNotEmpty ? expoName : '订单详情',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.44),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              _statusLabel(status),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. 展会信息卡 (Figma: separate card) ──
  Widget _orderExpoCard(Map<String, dynamic> req) {
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
            '展会信息',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
          ),
          const SizedBox(height: 14),
          _labelValueRow('展馆地点', '${req['city'] ?? ''} · ${req['venue'] ?? ''}'),
          const Divider(height: 1, color: Color(0xFFF9FAFB)),
          _labelValueRow('展会日期', '${req['dateStart'] ?? ''} ~ ${req['dateEnd'] ?? ''}'),
          const Divider(height: 1, color: Color(0xFFF9FAFB)),
          _labelValueRow('语言组合', (req['languagePairs'] as List?)?.join(' / ') ?? ''),
          if ((req['translationType'] ?? '').toString().isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF9FAFB)),
            _labelValueRow('翻译类型', req['translationType'] ?? ''),
          ],
        ],
      ),
    );
  }

  // ── 2b. 客户信息卡 (Figma: separate card) ──
  Widget _orderContactCard(Map<String, dynamic> req) {
    final contactName = (req['contactName'] ?? '').toString();
    if (contactName.isEmpty) return const SizedBox.shrink();
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
            '客户信息',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
          ),
          const SizedBox(height: 14),
          if ((req['companyName'] ?? '').toString().isNotEmpty) ...[
            _labelValueRow('公司名称', req['companyName'] ?? ''),
            const Divider(height: 1, color: Color(0xFFF9FAFB)),
          ],
          _labelValueRow('联系人', contactName),
        ],
      ),
    );
  }

  Widget _labelValueRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.subtitle)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. 报价卡（单价 × 天数 = 总价）──
  Widget _orderPriceCard(Map<String, dynamic> q) {
    final unitAmount = (q['amountAed'] as num?)?.toDouble() ?? 0;
    final days = (q['serviceDays'] as num?)?.toInt() ?? 1;
    final quoteType = q['quoteType'] as String? ?? 'DAILY';
    final taxLabel = q['taxType'] == 'TAX_INCLUDED' ? '含税' : '不含税';
    final remark = (q['remark'] ?? '').toString();

    // 计算总价
    double totalAmount;
    String unitLabel;
    String breakdownText;
    switch (quoteType) {
      case 'DAILY':
        totalAmount = unitAmount * days;
        unitLabel = '/天';
        breakdownText =
            'AED ${unitAmount.toStringAsFixed(0)}$unitLabel × $days 天 · $taxLabel';
        break;
      case 'HOURLY':
        totalAmount = unitAmount * days; // serviceDays 语义复用为小时数
        unitLabel = '/时';
        breakdownText =
            'AED ${unitAmount.toStringAsFixed(0)}$unitLabel × $days 小时 · $taxLabel';
        break;
      case 'PROJECT':
      default:
        totalAmount = unitAmount;
        unitLabel = '按项目';
        breakdownText = '按项目报价 · $taxLabel';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '总价',
            style: TextStyle(color: AppColors.subtitle, fontSize: 12, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'AED ${totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            breakdownText,
            style: const TextStyle(color: AppColors.subtitle, fontSize: 13),
          ),
          if (remark.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                remark,
                style: const TextStyle(color: AppColors.bodyText, fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 4. 翻译员 / 雇主信息卡 ──
  Widget _orderCounterpartCard(Map<String, dynamic> d) {
    final isEmployerView = widget.isEmployer;
    final roleLabel = isEmployerView ? '翻译员' : '雇主';
    final name = d['counterpartName'] ?? '';

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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEmployerView ? Icons.record_voice_over_outlined : Icons.business_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.subtitle, size: 20),
        ],
      ),
    );
  }

  // ── 5. Figma-style 状态时间线 ──
  static const _defaultSteps = ['需求已提交', '平台匹配中', '翻译已报价', '雇主已确认', '服务进行中', '服务已完成'];

  Widget _orderTimelineCard(List<Map<String, dynamic>> timelines, String orderStatus) {
    // Build a merged timeline: real events + default remaining steps
    final completedTexts = timelines.map((t) => t['eventText'] as String? ?? '').toSet();
    final completedCount = timelines.length;

    // Map real timeline events with their times
    final List<Map<String, dynamic>> steps = [];
    for (final t in timelines) {
      steps.add({'text': t['eventText'] ?? '', 'time': t['createdAt'], 'completed': true});
    }
    // Add remaining default steps that haven't happened yet
    for (int i = completedCount; i < _defaultSteps.length; i++) {
      if (!completedTexts.contains(_defaultSteps[i])) {
        steps.add({'text': _defaultSteps[i], 'time': null, 'completed': false});
      }
    }

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
            '状态时间线',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            final isLast = idx == steps.length - 1;
            final isCompleted = step['completed'] == true;
            final createdAt = step['time'] as int?;
            String timeStr = '';
            if (createdAt != null) {
              final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
              timeStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            }
            return _figmaTimelineNode(
              text: step['text'] as String,
              time: timeStr,
              isCompleted: isCompleted,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _figmaTimelineNode({
    required String text,
    required String time,
    required bool isCompleted,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: isCompleted ? AppColors.primary : const Color(0xFFC0C0C0),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.primary : const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isCompleted ? AppColors.darkText : const Color(0xFFC0C0C0),
                      fontSize: 14,
                      fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(time, style: const TextStyle(fontSize: 12, color: AppColors.subtitle)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ 雇主操作按钮 ═══
  Widget _buildEmployerActions(String status) {
    // 待完成确认：显示"确认服务完成"
    if (status == 'PENDING_EMPLOYER_CONFIRMATION') {
      return Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _actionLoading ? null : () => _confirmOrderCompletion(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
              elevation: 0,
            ),
            child: _actionLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('确认服务完成', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    // 已完成：根据 hasReview 决定是否显示"去评价"
    if (status == 'COMPLETED') {
      final hasReview = _data?['hasReview'] == true;
      if (hasReview) {
        return Container(
          padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, -2))],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
              ),
              child: const Text('已评价', style: TextStyle(color: AppColors.subtitle, fontSize: 14)),
            ),
          ),
        );
      }
      // 未评价：显示"去评价"按钮
      return Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: () => _openReviewPage(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBBF24),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
              elevation: 0,
            ),
            child: const Text('去评价', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _openReviewPage() async {
    final translatorName = _data?['counterpartName'] as String? ?? '翻译员';
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitReviewPage(
          orderId: widget.orderId!,
          translatorName: translatorName,
          translatorAvatar: _data?['counterpartAvatar'] as String?,
          orderNo: _data?['orderNo'] as String?,
          expoName: _data?['expoName'] as String?,
          dateRange: _data?['dateRange'] as String?,
          serviceType: _data?['serviceType'] as String?,
        ),
      ),
    );
    if (submitted == true && mounted) {
      _loadData(); // 刷新以更新 hasReview → true，按钮变为"已评价"
    }
  }

  Future<void> _confirmOrderCompletion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认服务完成'),
        content: const Text('确认翻译员已完成服务吗？确认后订单将标记为已完成。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _actionLoading = true);
    try {
      final service = context.read<EmployerService>();
      await service.confirmOrderCompletion(widget.orderId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('服务完成确认成功')));
        _loadData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
    if (mounted) setState(() => _actionLoading = false);
  }

  // ═══ 翻译员操作按钮 ═══
  Widget _buildTranslatorActions(String status, int? confirmedArrivalAt) {
    final actions = _availableActions(status, confirmedArrivalAt);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: actions.map((a) {
          final isPrimary = a['primary'] == true;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                height: 46,
                child: isPrimary
                    ? ElevatedButton(
                        onPressed: _actionLoading ? null : () => _doAction(a['action'] as String),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: a['color'] as Color? ?? AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                          elevation: 0,
                        ),
                        child: _actionLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(a['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      )
                    : OutlinedButton(
                        onPressed: _actionLoading ? null : () => _doAction(a['action'] as String),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: a['color'] as Color? ?? AppColors.primary,
                          side: BorderSide(color: a['color'] as Color? ?? AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                        ),
                        child: Text(a['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _availableActions(String status, int? confirmedArrivalAt) {
    switch (status) {
      case 'PENDING_CONFIRM':
        return [
          {'action': 'CANCEL_ORDER', 'label': '取消订单', 'color': Colors.red, 'primary': false},
          {'action': 'CONFIRM_SCHEDULE', 'label': '确认档期', 'color': AppColors.primary, 'primary': true},
        ];
      case 'CONFIRMED':
        // 未确认到场时：显示"确认到场"
        // 已确认到场时：显示"开始服务"，"确认到场"按钮消失
        final hasConfirmedArrival = confirmedArrivalAt != null;
        if (!hasConfirmedArrival) {
          return [
            {'action': 'CANCEL_ORDER', 'label': '取消订单', 'color': Colors.red, 'primary': false},
            {'action': 'CONFIRM_ARRIVAL', 'label': '确认到场', 'color': AppColors.primary, 'primary': true},
          ];
        } else {
          return [
            {'action': 'CANCEL_ORDER', 'label': '取消订单', 'color': Colors.red, 'primary': false},
            {'action': 'START_SERVICE', 'label': '开始服务', 'color': AppColors.primary, 'primary': true},
          ];
        }
      case 'IN_SERVICE':
        return [
          {'action': 'CANCEL_ORDER', 'label': '取消订单', 'color': Colors.red, 'primary': false},
          {'action': 'COMPLETE_SERVICE', 'label': '完成服务', 'color': const Color(0xFF00A63E), 'primary': true},
        ];
      default:
        return [];
    }
  }

  Future<void> _doAction(String action) async {
    final actionLabels = {
      'CONFIRM_SCHEDULE': '确认档期',
      'CONFIRM_ARRIVAL': '确认到场',
      'START_SERVICE': '开始服务',
      'COMPLETE_SERVICE': '完成服务',
      'CANCEL_ORDER': '取消订单',
    };

    if (action == 'CANCEL_ORDER') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('取消订单'),
          content: const Text('确定要取消此订单吗？此操作不可撤回。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('再想想')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('确认取消')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _actionLoading = true);
    try {
      final service = context.read<TranslatorService>();
      await service.orderAction(widget.orderId!, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${actionLabels[action] ?? action}成功')));
        _loadData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
    if (mounted) setState(() => _actionLoading = false);
  }

  // ═══ 通用辅助 ═══
  String _formatRequestDateRange(String start, String end) {
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      final days = e.difference(s).inDays + 1;
      return '${s.month}月${s.day}日-${e.month}月${e.day}日($days天)';
    } catch (_) {
      return '$start ~ $end';
    }
  }

  String _statusLabel(String status) {
    const map = {
      'PENDING_QUOTE': '待报价', 'PENDING_CONFIRM': '待确认',
      'CONFIRMED': '已确认', 'IN_SERVICE': '服务中',
      'PENDING_EMPLOYER_CONFIRMATION': '待完成确认',
      'COMPLETED': '已完成', 'CANCELLED': '已取消',
    };
    return map[status] ?? status;
  }

  String _requestStatusLabel(String status) {
    const map = {'OPEN': '开放中', 'QUOTING': '报价中', 'CLOSED': '已关闭'};
    return map[status] ?? status;
  }

  String _quoteStatusLabel(String status) {
    const map = {'SUBMITTED': '待确认', 'ACCEPTED': '已接受', 'REJECTED': '已拒绝'};
    return map[status] ?? status;
  }

  String _quoteTypeLabel(String type) {
    const map = {'DAILY': '按天', 'HOURLY': '按时', 'PROJECT': '按项目'};
    return map[type] ?? type;
  }
}
