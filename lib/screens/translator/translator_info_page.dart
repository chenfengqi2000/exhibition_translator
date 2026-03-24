import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/filter_options.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/translator_provider.dart';
import '../../services/translator_service.dart';
import 'my_reviews_page.dart';

class TranslatorInfoPage extends StatefulWidget {
  const TranslatorInfoPage({super.key});

  @override
  State<TranslatorInfoPage> createState() => _TranslatorInfoPageState();
}

class _TranslatorInfoPageState extends State<TranslatorInfoPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TranslatorProvider>().loadMyProfile();
    });
  }

  void _openEdit(TranslatorProfile? current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(
        initial: current,
        onSaved: (updated) {
          context.read<TranslatorProvider>().saveMyProfile(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthProvider>().user?.name ?? '用户';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '我的资料',
          style: TextStyle(color: AppColors.darkText, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          Consumer<TranslatorProvider>(
            builder: (_, prov, __) => TextButton(
              onPressed: () => _openEdit(prov.myProfile),
              child: const Text(
                '编辑',
                style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<TranslatorProvider>(
        builder: (context, prov, _) {
          if (prov.profileLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildProfileHeader(userName),
                const SizedBox(height: 28),
                if (prov.myProfile == null)
                  _buildEmptyHint(prov.myProfile)
                else ...[
                  _buildInfoCard(icon: Icons.person_outline, label: '真实姓名',
                      value: prov.myProfile!.realName.isEmpty ? '未填写' : prov.myProfile!.realName),
                  _buildInfoCard(icon: Icons.language, label: '语言能力',
                      value: prov.myProfile!.languagePairs.isEmpty ? '未填写' : prov.myProfile!.languagePairs.join(', ')),
                  _buildInfoCard(icon: Icons.location_city_outlined, label: '服务城市',
                      value: prov.myProfile!.serviceCities.isEmpty ? '未填写' : prov.myProfile!.serviceCities.join(', ')),
                  _buildInfoCard(icon: Icons.work_outline, label: '服务类型',
                      value: prov.myProfile!.serviceTypes.isEmpty ? '未填写' : prov.myProfile!.serviceTypes.join(', ')),
                  _buildInfoCard(icon: Icons.factory_outlined, label: '擅长行业',
                      value: prov.myProfile!.industries.isEmpty ? '未填写' : prov.myProfile!.industries.join(', ')),
                  _buildInfoCard(icon: Icons.star_outline, label: '展会经验',
                      value: prov.myProfile!.expoExperience.isEmpty ? '未填写' : prov.myProfile!.expoExperience),
                  _buildInfoCard(
                    icon: Icons.payments_outlined,
                    label: '日费 (AED)',
                    value: prov.myProfile!.dailyRateAed != null
                        ? prov.myProfile!.dailyRateAed!.toStringAsFixed(0)
                        : '未填写',
                  ),
                  _buildInfoCard(icon: Icons.business_outlined, label: '常驻展馆',
                      value: prov.myProfile!.serviceVenues.isEmpty ? '未填写' : prov.myProfile!.serviceVenues.join(', ')),
                  _buildInfoCard(icon: Icons.notes_outlined, label: '自我介绍',
                      value: prov.myProfile!.intro.isEmpty ? '未填写' : prov.myProfile!.intro),
                  _buildInfoCard(icon: Icons.verified_outlined, label: '审核状态',
                      value: _auditLabel(prov.myProfile!.auditStatus)),
                  _buildReviewCenterEntry(),
                  if (prov.myProfile!.auditStatus != 'APPROVED')
                    _buildDevApproveButton(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _auditLabel(String status) {
    switch (status) {
      case 'PENDING_SUBMISSION': return '待提交';
      case 'UNDER_REVIEW': return '审核中';
      case 'NEED_SUPPLEMENT': return '需补充';
      case 'APPROVED': return '已通过';
      default: return status;
    }
  }

  Widget _buildEmptyHint(TranslatorProfile? profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(Icons.edit_note, size: 48, color: AppColors.primary.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('还没有填写资料', style: TextStyle(color: AppColors.subtitle, fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _openEdit(profile),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              shape: const StadiumBorder(), elevation: 0,
            ),
            child: const Text('立即填写'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String userName) {
    return Column(
      children: [
        const CircleAvatar(radius: 40, backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 42, color: Colors.white)),
        const SizedBox(height: 14),
        Text(userName, style: const TextStyle(color: AppColors.darkText, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Text('翻译员', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildReviewCenterEntry() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsPage()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: const Row(
          children: [
            Icon(Icons.star_rounded, size: 22, color: Color(0xFFFBBF24)),
            SizedBox(width: 12),
            Expanded(
              child: Text('评价中心', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.darkText)),
            ),
            Text('查看收到的评价', style: TextStyle(fontSize: 13, color: AppColors.subtitle)),
            SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: AppColors.subtitle),
          ],
        ),
      ),
    );
  }

  bool _devApproving = false;

  Widget _buildDevApproveButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFBBF24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, color: Color(0xFFD97706), size: 18),
              SizedBox(width: 6),
              Text('开发环境', style: TextStyle(color: Color(0xFFD97706), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('点击下方按钮模拟审核通过，仅开发/测试环境使用', style: TextStyle(color: Color(0xFF92400E), fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: _devApproving ? null : _handleDevApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: const Color(0xFF78350F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _devApproving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF78350F)))
                  : const Text('模拟审核通过', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDevApprove() async {
    setState(() => _devApproving = true);
    try {
      final service = context.read<TranslatorService>();
      await service.devApproveProfile();
      if (mounted) {
        context.read<TranslatorProvider>().loadMyProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('审核已通过！现在可以查看需求和提交报价了')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
    if (mounted) setState(() => _devApproving = false);
  }

  Widget _buildInfoCard({required IconData icon, required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.subtitle, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppColors.darkText, fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 编辑底部表单 ──────────────────────────────────────────────────────────────

class _EditSheet extends StatefulWidget {
  final TranslatorProfile? initial;
  final ValueChanged<TranslatorProfile> onSaved;
  const _EditSheet({this.initial, required this.onSaved});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _introCtrl;

  // 语言能力：单选，用 String 存储
  late String _selectedLang;
  late List<String> _selectedCities;
  late List<String> _selectedVenues;
  late List<String> _selectedServiceTypes;
  late List<String> _selectedIndustries;
  late String _selectedExpoExp;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _nameCtrl = TextEditingController(text: p?.realName ?? '');
    _priceCtrl = TextEditingController(
        text: p?.dailyRateAed?.toStringAsFixed(0) ?? '');
    _introCtrl = TextEditingController(text: p?.intro ?? '');

    // 语言能力单选：取列表第一项（或空字符串）
    _selectedLang = (p?.languagePairs.isNotEmpty == true) ? p!.languagePairs.first : '';
    _selectedCities = List<String>.from(p?.serviceCities ?? []);
    _selectedVenues = List<String>.from(p?.serviceVenues ?? []);
    _selectedServiceTypes = List<String>.from(p?.serviceTypes ?? []);
    _selectedIndustries = List<String>.from(p?.industries ?? []);
    _selectedExpoExp = p?.expoExperience ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _introCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_selectedLang.isEmpty) return '请选择语言能力';
    if (_selectedExpoExp.isEmpty) return '请选择展会经验';
    if (_selectedCities.isEmpty) return '请选择至少一个服务城市';
    if (_selectedServiceTypes.isEmpty) return '请选择至少一种翻译类型';
    if (_selectedIndustries.isEmpty) return '请选择至少一个擅长行业';
    if (_priceCtrl.text.trim().isEmpty) return '请填写日费（AED）';
    if (double.tryParse(_priceCtrl.text.trim()) == null) return '日费请输入有效数字';
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final dailyPrice = double.tryParse(_priceCtrl.text.trim());
    final profile = TranslatorProfile(
      realName: _nameCtrl.text.trim(),
      languagePairs: [_selectedLang],
      serviceCities: _selectedCities,
      serviceVenues: _selectedVenues,
      serviceTypes: _selectedServiceTypes,
      industries: _selectedIndustries,
      expoExperience: _selectedExpoExp,
      dailyRateAed: dailyPrice,
      intro: _introCtrl.text.trim(),
    );
    widget.onSaved(profile);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
              const Text('编辑资料', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.darkText)),
              const SizedBox(height: 20),
              _textField('真实姓名', _nameCtrl, hint: '您的真实姓名'),
              _radioSection('语言能力（单选）', FilterOptions.languagePairs, _selectedLang, (v) {
                setState(() => _selectedLang = v);
              }),
              _chipSection('服务城市（可多选）', FilterOptions.cities, _selectedCities),
              _chipSection('常驻展馆（可多选）', FilterOptions.venues, _selectedVenues),
              _chipSection('翻译类型（可多选）', FilterOptions.serviceTypes, _selectedServiceTypes),
              _chipSection('擅长行业（可多选）', FilterOptions.industries, _selectedIndustries),
              _radioSection('展会经验（单选）', FilterOptions.expoExperience, _selectedExpoExp, (v) {
                setState(() => _selectedExpoExp = v);
              }),
              _textField('日费 (AED)', _priceCtrl, hint: '如：800', keyboard: TextInputType.number),
              _textField('自我介绍', _introCtrl, hint: '简短描述您的经验和优势', maxLines: 3),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    shape: const StadiumBorder(), elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController ctrl,
      {String? hint, int maxLines = 1, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.subtitle)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl, maxLines: maxLines, keyboardType: keyboard,
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
          ),
        ],
      ),
    );
  }

  Widget _chipSection(String label, List<String> options, List<String> selected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.subtitle)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = selected.contains(opt);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selected.remove(opt);
                    } else {
                      selected.add(opt);
                    }
                  });
                },
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

  Widget _radioSection(String label, List<String> options, String selected, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.subtitle)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = selected == opt;
              return GestureDetector(
                onTap: () => onChanged(opt),
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
}
