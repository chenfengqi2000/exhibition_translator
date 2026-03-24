import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/employer_service.dart';
import 'submit_success_page.dart';

class SubmitDemandPage extends StatefulWidget {
  const SubmitDemandPage({super.key});

  @override
  State<SubmitDemandPage> createState() => _SubmitDemandPageState();
}

class _SubmitDemandPageState extends State<SubmitDemandPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  final _industryController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _remarkController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _companyNameController = TextEditingController();

  String _city = 'Dubai';
  String _languagePair = 'ZH-EN';
  String _serviceType = 'Booth';
  DateTime? _dateStart;
  DateTime? _dateEnd;
  bool _invoiceRequired = false;
  bool _submitting = false;

  static const _cityMap = {
    'Dubai': '迪拜',
    'Abu Dhabi': '阿布扎比',
    'Sharjah': '沙迦',
  };

  static const _languageMap = {
    'ZH-EN': '中文 ↔ 英文',
    'ZH-EN,ZH-AR': '中英阿',
    'EN-AR': '英文 ↔ 阿拉伯文',
  };

  static const _serviceTypeMap = {
    'Booth': '陪同翻译',
    'Business': '商务翻译',
    'Conference': '会议翻译',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _industryController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _remarkController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  int get _days {
    if (_dateStart == null || _dateEnd == null) return 0;
    return _dateEnd!.difference(_dateStart!).inDays + 1;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '请选择';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_dateStart ?? now) : (_dateEnd ?? _dateStart ?? now);
    final first = isStart ? now : (_dateStart ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('zh'),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _dateStart = picked;
          if (_dateEnd != null && _dateEnd!.isBefore(picked)) {
            _dateEnd = null;
          }
        } else {
          _dateEnd = picked;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateStart == null || _dateEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择展会日期')),
      );
      return;
    }

    final budgetMin = double.tryParse(_budgetMinController.text);
    final budgetMax = double.tryParse(_budgetMaxController.text);
    if (budgetMin == null || budgetMax == null || budgetMin > budgetMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写正确的预算范围')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final languagePairs = _languagePair.split(',');
      final service = context.read<EmployerService>();
      final result = await service.createRequest({
        'expoName': _nameController.text.trim(),
        'city': _city,
        'venue': _venueController.text.trim(),
        'dateStart': _formatDate(_dateStart),
        'dateEnd': _formatDate(_dateEnd),
        'languagePairs': languagePairs,
        'translationType': _serviceType,
        'industry': _industryController.text.trim(),
        'budgetMinAed': budgetMin,
        'budgetMaxAed': budgetMax,
        'contactName': _contactNameController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'invoiceRequired': _invoiceRequired,
        'remark': _remarkController.text.trim(),
      });

      if (mounted) {
        final requestId = result['id'] as int;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SubmitSuccessPage(requestId: requestId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e')),
        );
      }
    }

    if (mounted) setState(() => _submitting = false);
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
          '提交翻译需求',
          style: TextStyle(color: AppColors.darkText, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSection(
                      icon: Icons.location_city,
                      title: '展会信息',
                      children: [
                        _buildTextField(label: '展会名称', controller: _nameController, required_: true),
                        _buildDropdownRow(
                          label: '展会城市',
                          value: _city,
                          options: _cityMap.keys.toList(),
                          displayMap: _cityMap,
                          onChanged: (v) => setState(() => _city = v),
                        ),
                        _buildTextField(label: '展馆地点', controller: _venueController, required_: true),
                        _buildDateRow(label: '开始日期', date: _dateStart, onTap: () => _pickDate(isStart: true)),
                        _buildDateRow(label: '结束日期', date: _dateEnd, onTap: () => _pickDate(isStart: false)),
                        _buildTextField(label: '行业领域', controller: _industryController, hint: '如：美容、建材、电子'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      icon: Icons.language,
                      title: '翻译需求',
                      children: [
                        _buildDropdownRow(
                          label: '语言组合',
                          value: _languagePair,
                          options: _languageMap.keys.toList(),
                          displayMap: _languageMap,
                          onChanged: (v) => setState(() => _languagePair = v),
                        ),
                        _buildDropdownRow(
                          label: '翻译类型',
                          value: _serviceType,
                          options: _serviceTypeMap.keys.toList(),
                          displayMap: _serviceTypeMap,
                          onChanged: (v) => setState(() => _serviceType = v),
                        ),
                        _buildInfoRow(label: '所需天数', value: _days > 0 ? '$_days天' : '由日期自动计算'),
                        _buildBudgetRow(),
                        _buildTextField(label: '备注', controller: _remarkController, maxLines: 3, hint: '其他需要说明的事项（选填）'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      icon: Icons.person,
                      title: '联系信息',
                      children: [
                        _buildTextField(label: '联系人', controller: _contactNameController, required_: true, hint: '请输入联系人姓名'),
                        _buildTextField(label: '联系电话', controller: _contactPhoneController, required_: true, hint: '请输入联系电话'),
                        _buildTextField(label: '公司名称', controller: _companyNameController, hint: '请输入公司名称（选填）'),
                        _buildSwitchRow(label: '需要发票', value: _invoiceRequired, onChanged: (v) => setState(() => _invoiceRequired = v)),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool required_ = false,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.subtitle)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint ?? '请输入$label',
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.subtitle),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 1),
              ),
            ),
            validator: required_
                ? (value) {
                    if (value == null || value.trim().isEmpty) return '请输入$label';
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> options,
    Map<String, String>? displayMap,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.subtitle)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: options.contains(value) ? value : options.first,
                isExpanded: true,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 14, color: AppColors.darkText),
                items: options.map((o) => DropdownMenuItem(
                  value: o,
                  child: Text(displayMap?[o] ?? o),
                )).toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.subtitle)),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontSize: 14,
                        color: date == null ? AppColors.subtitle : AppColors.darkText,
                      ),
                    ),
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.subtitle),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.subtitle)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.darkText)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.subtitle))),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildBudgetRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('预算范围 (AED/天)', style: TextStyle(fontSize: 13, color: AppColors.subtitle)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _budgetMinController,
                  keyboardType: TextInputType.number,
                  decoration: _budgetInputDecoration('最低'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '必填';
                    if (double.tryParse(v) == null) return '数字';
                    return null;
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('~', style: TextStyle(color: AppColors.subtitle)),
              ),
              Expanded(
                child: TextFormField(
                  controller: _budgetMaxController,
                  keyboardType: TextInputType.number,
                  decoration: _budgetInputDecoration('最高'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '必填';
                    if (double.tryParse(v) == null) return '数字';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _budgetInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.subtitle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _submitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            elevation: 0,
          ),
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('提交需求', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
