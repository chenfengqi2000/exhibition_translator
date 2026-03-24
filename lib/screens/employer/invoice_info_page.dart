import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class InvoiceInfoPage extends StatefulWidget {
  const InvoiceInfoPage({super.key});

  /// 从 SharedPreferences 读取已保存的开票信息（供其他页面调用）
  static Future<Map<String, dynamic>?> getSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json == null || json.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(json));
  }

  static const String _prefsKey = 'invoice_info';

  @override
  State<InvoiceInfoPage> createState() => _InvoiceInfoPageState();
}

class _InvoiceInfoPageState extends State<InvoiceInfoPage> {
  int _selectedType = 0;
  bool _isDefault = true;
  bool _loading = true;

  final _companyController = TextEditingController();
  final _titleController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final saved = await InvoiceInfoPage.getSavedInfo();
    if (saved != null && mounted) {
      setState(() {
        _selectedType = saved['type'] as int? ?? 0;
        _isDefault = saved['isDefault'] as bool? ?? true;
        _companyController.text = saved['company'] as String? ?? '';
        _titleController.text = saved['title'] as String? ?? '';
        _taxIdController.text = saved['taxId'] as String? ?? '';
        _emailController.text = saved['email'] as String? ?? '';
        _addressController.text = saved['address'] as String? ?? '';
        _phoneController.text = saved['phone'] as String? ?? '';
        _remarkController.text = saved['remark'] as String? ?? '';
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _companyController.dispose();
    _titleController.dispose();
    _taxIdController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _remarkController.dispose();
    super.dispose();
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
          '开票信息',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.darkText),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTipBanner(),
                        const SizedBox(height: 16),
                        _buildTypeSelector(),
                        const SizedBox(height: 16),
                        _buildFormCard(),
                        const SizedBox(height: 16),
                        _buildDefaultToggle(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildSaveButton(),
              ],
            ),
    );
  }

  Widget _buildTipBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '发票将根据您填写的信息开具，请确保信息准确',
              style: TextStyle(fontSize: 13, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [_buildTypeTab('企业发票', 0), _buildTypeTab('个人发票', 1)]),
    );
  }

  Widget _buildTypeTab(String label, int index) {
    final selected = _selectedType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.bodyText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          if (_selectedType == 0) ...[
            _buildTextField(label: '公司名称', required: true, controller: _companyController, hint: '请输入公司名称'),
            _buildFieldDivider(),
          ],
          _buildTextField(label: '发票抬头', required: true, controller: _titleController, hint: '请输入发票抬头'),
          _buildFieldDivider(),
          if (_selectedType == 0) ...[
            _buildTextField(label: '税号', required: true, controller: _taxIdController, hint: '请输入纳税人识别号', helperText: '统一社会信用代码/纳税人识别号'),
            _buildFieldDivider(),
          ],
          _buildAmountInfo(),
          _buildFieldDivider(),
          _buildTextField(label: '接收邮箱', required: true, controller: _emailController, hint: '请输入接收发票的邮箱', keyboardType: TextInputType.emailAddress),
          _buildFieldDivider(),
          _buildTextField(label: '收件地址', required: false, controller: _addressController, hint: '请输入纸质发票收件地址（选填）', maxLines: 2),
          _buildFieldDivider(),
          _buildTextField(label: '联系电话', required: false, controller: _phoneController, hint: '请输入联系电话（选填）', keyboardType: TextInputType.phone),
          _buildFieldDivider(),
          _buildTextField(label: '备注', required: false, controller: _remarkController, hint: '请输入备注信息（选填）', maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required bool required,
    required TextEditingController controller,
    required String hint,
    String? helperText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (required) const Text('*', style: TextStyle(fontSize: 14, color: Colors.redAccent)),
            if (required) const SizedBox(width: 2),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText)),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: AppColors.darkText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.subtitle),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1)),
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 4),
            Text(helperText, style: const TextStyle(fontSize: 12, color: AppColors.subtitle)),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('开票金额', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.subtitle),
              SizedBox(width: 8),
              Text('开票金额以实际订单结算金额为准', style: TextStyle(fontSize: 13, color: AppColors.bodyText)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldDivider() => const Divider(height: 1, color: AppColors.border);

  Widget _buildDefaultToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Expanded(
          child: Text('设为默认开票信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText)),
        ),
        Switch(
          value: _isDefault,
          onChanged: (v) => setState(() => _isDefault = v),
          activeTrackColor: AppColors.primary,
        ),
      ]),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: const Text('保存开票信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_titleController.text.trim().isEmpty) { _showError('请输入发票抬头'); return; }
    if (_selectedType == 0 && _companyController.text.trim().isEmpty) { _showError('请输入公司名称'); return; }
    if (_selectedType == 0 && _taxIdController.text.trim().isEmpty) { _showError('请输入税号'); return; }
    if (_emailController.text.trim().isEmpty) { _showError('请输入接收邮箱'); return; }

    final data = {
      'type': _selectedType,
      'isDefault': _isDefault,
      'company': _companyController.text.trim(),
      'title': _titleController.text.trim(),
      'taxId': _taxIdController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'phone': _phoneController.text.trim(),
      'remark': _remarkController.text.trim(),
      'savedAt': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(InvoiceInfoPage._prefsKey, jsonEncode(data));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('开票信息已保存'), backgroundColor: Color(0xFF00A63E)),
      );
      Navigator.pop(context, true); // return true to indicate save success
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }
}
