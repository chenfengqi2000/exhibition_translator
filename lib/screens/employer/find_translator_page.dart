import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/filter_options.dart';
import '../../theme/app_theme.dart';
import '../../models/translator.dart';
import '../../providers/translator_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/translator_card.dart';
import '../../widgets/state_widgets.dart';
import 'translator_detail_page.dart';

class FindTranslatorPage extends StatefulWidget {
  const FindTranslatorPage({super.key});

  @override
  State<FindTranslatorPage> createState() => _FindTranslatorPageState();
}

class _FindTranslatorPageState extends State<FindTranslatorPage> {
  // 搜索状态
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // 筛选状态
  String? _city;
  String? _languagePair;
  String? _translationType;
  String? _industry;
  String? _expoExperience;
  double? _budgetMin;
  double? _budgetMax;

  int _activeFilterCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _doSearch();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Translator> _getFilteredTranslators(List<Translator> translators) {
    if (_searchQuery.isEmpty) return translators;
    final query = _searchQuery.toLowerCase();
    return translators.where((t) {
      if (t.name.toLowerCase().contains(query)) return true;
      if (t.languagePairs.join(' ').toLowerCase().contains(query)) return true;
      if (t.serviceCities.join(' ').toLowerCase().contains(query)) return true;
      if (t.industries.join(' ').toLowerCase().contains(query)) return true;
      return false;
    }).toList();
  }

  void _updateFilterCount() {
    int count = 0;
    if (_city != null) count++;
    if (_languagePair != null) count++;
    if (_translationType != null) count++;
    if (_industry != null) count++;
    if (_expoExperience != null) count++;
    if (_budgetMin != null || _budgetMax != null) count++;
    _activeFilterCount = count;
  }

  Future<void> _doSearch() async {
    _updateFilterCount();
    final translatorProvider = context.read<TranslatorProvider>();
    await translatorProvider.loadTranslators(
      city: _city,
      languagePair: _languagePair,
      translationType: _translationType,
      industry: _industry,
      expoExperience: _expoExperience,
      budgetMin: _budgetMin,
      budgetMax: _budgetMax,
    );
    // 同步服务端返回的 isFavorited 字段到本地缓存
    if (mounted) {
      context.read<FavoriteProvider>().syncFromTranslatorList(translatorProvider.translators);
    }
  }

  void _clearFilters() {
    setState(() {
      _city = null;
      _languagePair = null;
      _translationType = null;
      _industry = null;
      _expoExperience = null;
      _budgetMin = null;
      _budgetMax = null;
    });
    _doSearch();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        city: _city,
        languagePair: _languagePair,
        translationType: _translationType,
        industry: _industry,
        expoExperience: _expoExperience,
        budgetMin: _budgetMin,
        budgetMax: _budgetMax,
        onApply: (city, lang, type, ind, expo, bMin, bMax) {
          setState(() {
            _city = city;
            _languagePair = lang;
            _translationType = type;
            _industry = ind;
            _expoExperience = expo;
            _budgetMin = bMin;
            _budgetMax = bMax;
          });
          _doSearch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title + search
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '找翻译',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    // Filter button with badge
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.tune, color: AppColors.darkText),
                          onPressed: _openFilterSheet,
                        ),
                        if (_activeFilterCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_activeFilterCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search box - same style as chat page
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: '搜索翻译员',
                      hintStyle: const TextStyle(
                        color: AppColors.subtitle,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.subtitle,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 18,
                                color: AppColors.subtitle,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 当前筛选标签
          if (_activeFilterCount > 0)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _buildActiveFilterChips(),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearFilters,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text('清除', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          // 结果列表
          Expanded(
            child: Consumer2<TranslatorProvider, FavoriteProvider>(
              builder: (context, provider, favProvider, _) {
                if (provider.isLoading) {
                  return const LoadingWidget();
                }
                if (provider.error != null) {
                  return ErrorRetryWidget(
                    message: provider.error!,
                    onRetry: _doSearch,
                  );
                }
                if (provider.translators.isEmpty) {
                  return const EmptyWidget(
                    message: '未找到匹配的翻译员',
                    icon: Icons.search_off,
                  );
                }

                final filtered = _getFilteredTranslators(provider.translators);
                if (filtered.isEmpty) {
                  return const EmptyWidget(
                    message: '未找到匹配的翻译员',
                    icon: Icons.search_off,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final translator = filtered[index];
                    return TranslatorCard(
                      translator: translator,
                      isFavorited: favProvider.isFavorited(translator.id),
                      onFavoriteToggle: () => favProvider.toggleFavorite(translator.id),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TranslatorDetailPage(translator: translator),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];
    if (_city != null) chips.add(_activeChip(_city!, () => setState(() { _city = null; _doSearch(); })));
    if (_languagePair != null) chips.add(_activeChip(_languagePair!, () => setState(() { _languagePair = null; _doSearch(); })));
    if (_translationType != null) chips.add(_activeChip(_translationType!, () => setState(() { _translationType = null; _doSearch(); })));
    if (_industry != null) chips.add(_activeChip(_industry!, () => setState(() { _industry = null; _doSearch(); })));
    if (_expoExperience != null) chips.add(_activeChip(_expoExperience!, () => setState(() { _expoExperience = null; _doSearch(); })));
    if (_budgetMin != null || _budgetMax != null) {
      final label = 'AED ${_budgetMin?.toInt() ?? 0} - ${_budgetMax?.toInt() ?? '...'}';
      chips.add(_activeChip(label, () => setState(() { _budgetMin = null; _budgetMax = null; _doSearch(); })));
    }
    return chips;
  }

  Widget _activeChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── 筛选面板 ──────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final String? city;
  final String? languagePair;
  final String? translationType;
  final String? industry;
  final String? expoExperience;
  final double? budgetMin;
  final double? budgetMax;
  final void Function(String?, String?, String?, String?, String?, double?, double?) onApply;

  const _FilterSheet({
    this.city, this.languagePair, this.translationType,
    this.industry, this.expoExperience, this.budgetMin, this.budgetMax,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _city;
  late String? _languagePair;
  late String? _translationType;
  late String? _industry;
  late String? _expoExperience;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _city = widget.city;
    _languagePair = widget.languagePair;
    _translationType = widget.translationType;
    _industry = widget.industry;
    _expoExperience = widget.expoExperience;
    _minCtrl = TextEditingController(text: widget.budgetMin?.toStringAsFixed(0) ?? '');
    _maxCtrl = TextEditingController(text: widget.budgetMax?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _city = null;
      _languagePair = null;
      _translationType = null;
      _industry = null;
      _expoExperience = null;
      _minCtrl.clear();
      _maxCtrl.clear();
    });
  }

  void _apply() {
    final bMin = double.tryParse(_minCtrl.text);
    final bMax = double.tryParse(_maxCtrl.text);
    widget.onApply(_city, _languagePair, _translationType, _industry, _expoExperience, bMin, bMax);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('筛选条件', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                GestureDetector(
                  onTap: _reset,
                  child: const Text('重置', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _filterSection('服务城市', FilterOptions.cities, _city, (v) => setState(() => _city = v)),
            _filterSection('语言能力', FilterOptions.languagePairs, _languagePair, (v) => setState(() => _languagePair = v)),
            _filterSection('翻译类型', FilterOptions.serviceTypes, _translationType, (v) => setState(() => _translationType = v)),
            _filterSection('擅长行业', FilterOptions.industries, _industry, (v) => setState(() => _industry = v)),
            _filterSection('展会经验', FilterOptions.expoExperience, _expoExperience, (v) => setState(() => _expoExperience = v)),
            _budgetSection(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: const StadiumBorder(), elevation: 0,
                ),
                child: const Text('应用筛选', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterSection(String label, List<String> options, String? selected, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.subtitle, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = selected == opt;
              return GestureDetector(
                onTap: () => onChanged(isSelected ? null : opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppColors.darkText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _budgetSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('日费预算 (AED)', style: TextStyle(fontSize: 13, color: AppColors.subtitle, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _budgetField(_minCtrl, '最低')),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('~', style: TextStyle(color: AppColors.subtitle, fontSize: 16)),
              ),
              Expanded(child: _budgetField(_maxCtrl, '最高')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _budgetField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.subtitle, fontSize: 14),
        filled: true, fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
