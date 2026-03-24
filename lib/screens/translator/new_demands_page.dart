import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/translator_service.dart';
import '../../widgets/state_widgets.dart';
import 'opportunity_detail_page.dart';

class NewDemandsPage extends StatefulWidget {
  const NewDemandsPage({super.key});

  @override
  State<NewDemandsPage> createState() => _NewDemandsPageState();
}

class _NewDemandsPageState extends State<NewDemandsPage> {
  List<Map<String, dynamic>> _demands = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCity = '';

  final _cityFilters = ['全部', 'Dubai', 'Abu Dhabi', 'Sharjah'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = context.read<TranslatorService>();
      final result = await service.listOpportunities(
        city: _selectedCity.isEmpty ? null : _selectedCity,
      );
      if (mounted) {
        setState(() {
          _demands = List<Map<String, dynamic>>.from(result['list'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
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
        centerTitle: true,
        title: const Text(
          '新需求',
          style: TextStyle(color: AppColors.darkText, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _cityFilters.map((filter) {
            final filterValue = filter == '全部' ? '' : filter;
            final isSelected = _selectedCity == filterValue;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedCity = filterValue);
                  _loadData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.bodyText,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget(message: '加载中...');
    if (_error != null) return ErrorRetryWidget(message: _error!, onRetry: _loadData);
    if (_demands.isEmpty) return const EmptyWidget(message: '暂无新需求');

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _demands.length,
        itemBuilder: (context, index) => _buildDemandCard(_demands[index]),
      ),
    );
  }

  Widget _buildDemandCard(Map<String, dynamic> demand) {
    final expoName = demand['expoName'] ?? '';
    final city = demand['city'] ?? '';
    final venue = demand['venue'] ?? '';
    final dateStart = demand['dateStart'] ?? '';
    final dateEnd = demand['dateEnd'] ?? '';
    final languagePairs = List<String>.from(demand['languagePairs'] ?? []);
    final translationType = demand['translationType'] ?? '';
    final industry = demand['industry'] ?? '';
    final budgetMin = demand['budgetMinAed'];
    final budgetMax = demand['budgetMaxAed'];
    final requestId = demand['id'] as int;

    String priceRange = '';
    if (budgetMin != null && budgetMax != null) {
      priceRange = 'AED ${budgetMin.toInt()}-${budgetMax.toInt()}/天';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OpportunityDetailPage(requestId: requestId),
          ),
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
            Text(
              expoName,
              style: const TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.subtitle, size: 16),
                const SizedBox(width: 4),
                Text('$city · $venue', style: const TextStyle(color: AppColors.subtitle, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: AppColors.subtitle, size: 15),
                const SizedBox(width: 4),
                Text('$dateStart ~ $dateEnd', style: const TextStyle(color: AppColors.subtitle, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (languagePairs.isNotEmpty) _buildTag(languagePairs.join(' / ')),
                if (translationType.isNotEmpty) _buildTag(translationType),
                if (industry.isNotEmpty) _buildTag(industry),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  priceRange,
                  style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const Icon(Icons.chevron_right, color: AppColors.subtitle, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
    );
  }
}
