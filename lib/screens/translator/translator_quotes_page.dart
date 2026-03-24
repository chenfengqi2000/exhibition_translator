import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/translator_service.dart';
import '../../widgets/state_widgets.dart';

class TranslatorQuotesPage extends StatefulWidget {
  const TranslatorQuotesPage({super.key});

  @override
  State<TranslatorQuotesPage> createState() => TranslatorQuotesPageState();
}

class TranslatorQuotesPageState extends State<TranslatorQuotesPage> {
  int _selectedTab = 0;
  List<Map<String, dynamic>> _quotes = [];
  bool _isLoading = true;
  String? _error;

  static const _tabs = ['全部', 'SUBMITTED', 'ACCEPTED', 'REJECTED'];
  static const _tabLabels = ['全部', '已提交', '已选中', '未选中'];

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = context.read<TranslatorService>();
      final status = _selectedTab == 0 ? null : _tabs[_selectedTab];
      final result = await service.listMyQuotes(status: status);
      if (mounted) {
        setState(() {
          _quotes = List<Map<String, dynamic>>.from(result['list'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void reload() => _loadQuotes();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('我的报价', style: TextStyle(color: AppColors.darkText, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = index == _selectedTab;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTab = index);
                  _loadQuotes();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _tabLabels[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.subtitle,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget(message: '加载中...');
    if (_error != null) return ErrorRetryWidget(message: _error!, onRetry: _loadQuotes);
    if (_quotes.isEmpty) return const EmptyWidget(message: '暂无报价记录');

    return RefreshIndicator(
      onRefresh: _loadQuotes,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _quotes.length,
        itemBuilder: (context, index) => _buildQuoteCard(_quotes[index]),
      ),
    );
  }

  Widget _buildQuoteCard(Map<String, dynamic> quote) {
    final status = quote['quoteStatus'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  quote['expoName'] ?? '未知需求',
                  style: const TextStyle(color: AppColors.darkText, fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.location_on_outlined, '${quote['city'] ?? ''} · ${quote['venue'] ?? ''}'),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_today_outlined, quote['dateRange'] ?? ''),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'AED ${(quote['amountAed'] ?? 0).toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                _quoteTypeLabel(quote['quoteType'] ?? ''),
                style: const TextStyle(color: AppColors.subtitle, fontSize: 12),
              ),
              const Spacer(),
              if (quote['requestStatus'] != null)
                Text(
                  '需求: ${_requestStatusLabel(quote['requestStatus'])}',
                  style: const TextStyle(color: AppColors.subtitle, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'SUBMITTED':
        bg = const Color(0xFFDBEAFE); fg = const Color(0xFF155DFC); label = '已提交';
        break;
      case 'ACCEPTED':
        bg = const Color(0xFFDCFCE7); fg = const Color(0xFF00A63E); label = '已选中';
        break;
      case 'REJECTED':
        bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626); label = '未选中';
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

  String _quoteTypeLabel(String type) {
    const map = {'HOURLY': '按小时', 'DAILY': '按天', 'PROJECT': '按项目'};
    return map[type] ?? type;
  }

  String _requestStatusLabel(String status) {
    const map = {'OPEN': '开放中', 'QUOTING': '报价中', 'CLOSED': '已关闭', 'CANCELLED': '已取消'};
    return map[status] ?? status;
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
