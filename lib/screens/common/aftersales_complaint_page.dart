import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/aftersales_provider.dart';
import '../../services/aftersales_service.dart';
import '../../services/employer_service.dart';
import '../../services/translator_service.dart';
import 'aftersales_detail_page.dart';

class AftersalesComplaintPage extends StatefulWidget {
  final Map<String, dynamic>? order;

  const AftersalesComplaintPage({super.key, this.order});

  @override
  State<AftersalesComplaintPage> createState() => _AftersalesComplaintPageState();
}

class _AftersalesComplaintPageState extends State<AftersalesComplaintPage> {
  Map<String, dynamic>? _selectedOrder;
  String? _selectedType;
  final _descController = TextEditingController();
  final List<Uint8List> _imageBytesList = [];
  bool _submitting = false;
  final _imagePicker = ImagePicker();

  String? _orderError;
  String? _typeError;
  String? _descError;
  String? _imageError;

  static const _employerProblemTypes = [
    '服务质量问题',
    '翻译员迟到/缺席',
    '翻译能力不符',
    '态度问题',
    '费用争议',
    '其他问题',
  ];

  static const _translatorProblemTypes = [
    '雇主临时变更服务安排',
    '实际服务内容与约定不符',
    '服务时长/天数争议',
    '结算金额有异议',
    '发票/税务问题',
    '雇主失联或沟通不畅',
    '现场条件影响正常服务',
    '其他问题',
  ];

  List<String> get _problemTypes {
    final role = context.read<AuthProvider>().role;
    return role == 'TRANSLATOR' ? _translatorProblemTypes : _employerProblemTypes;
  }

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _selectedOrder = Map<String, dynamic>.from(widget.order!);
      // 进入页面后立即检查是否已有处理中售后单
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkDuplicateAftersales(_selectedOrder);
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  bool get _isOrderFromWidget => widget.order != null;

  /// 计算订单总价文本。
  /// 优先使用嵌套 quote 对象计算（来自订单详情页跳转时携带完整数据），
  /// 否则退回 quoteSummary 字符串，再否则返回空字符串。
  String _computeOrderTotalText(Map<String, dynamic> order) {
    final quote = order['quote'] as Map<String, dynamic>?;
    if (quote != null) {
      final unit = (quote['amountAed'] as num?)?.toDouble();
      final days = (quote['serviceDays'] as num?)?.toInt() ?? 1;
      final quoteType = quote['quoteType'] as String? ?? 'DAILY';
      if (unit != null) {
        final total = quoteType == 'PROJECT' ? unit : unit * days;
        final totalStr = total == total.truncateToDouble()
            ? total.toInt().toString()
            : total.toStringAsFixed(2);
        return 'AED $totalStr';
      }
    }
    final summary = (order['quoteSummary'] ?? '').toString();
    return summary;
  }

  /// 检查该订单是否已有未关闭的售后单（先确保缓存已加载）。
  /// 如有，弹出提示并提供跳转入口，禁止重复创建。
  Future<void> _checkDuplicateAftersales(Map<String, dynamic>? order) async {
    if (order == null || !mounted) return;
    final orderId = (order['id'] as num?)?.toInt();
    if (orderId == null) return;

    final provider = context.read<AftersalesProvider>();
    await provider.ensureLoaded();
    if (!mounted) return;
    if (!provider.isOrderAftersalesOpen(orderId)) return;

    final existing = provider.findByOrderId(orderId)!;
    final existingId = existing['id'] as int?;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('已有处理中售后单'),
        content: const Text('该订单已有一条处理中的售后申请，不能重复创建。\n请查看已有售后进度，或等待处理完成后再次发起。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('返回'),
          ),
          if (existingId != null)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AftersalesDetailPage(aftersaleId: existingId),
                    ),
                  );
                }
              },
              child: const Text('查看售后进度'),
            ),
        ],
      ),
    );
  }

  String _orderDisplayText(Map<String, dynamic> order) {
    final orderNo = order['orderNo'] ?? 'ORD-${(order['id'] ?? '').toString().padLeft(6, '0')}';
    final expo = order['expoName'] ?? '';
    return '$orderNo · $expo';
  }

  String _orderSubtitleText(Map<String, dynamic> order) {
    final counterpart = order['counterpartName'] ?? '';
    final dateRange = order['dateRange'] ?? '';
    return '对方：$counterpart · $dateRange';
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
        title: const Text('售后/投诉', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.darkText)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildOrderCard(),
                  const SizedBox(height: 12),
                  _buildTypeCard(),
                  const SizedBox(height: 12),
                  _buildDescCard(),
                  const SizedBox(height: 12),
                  _buildUploadCard(),
                ],
              ),
            ),
          ),
          _buildSubmitBar(),
        ],
      ),
    );
  }

  // ── Order card ──
  Widget _buildOrderCard() {
    final hasOrder = _selectedOrder != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('关联订单', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText)),
              const Text(' *', style: TextStyle(fontSize: 15, color: Colors.red)),
              const Spacer(),
              if (hasOrder && !_isOrderFromWidget)
                GestureDetector(
                  onTap: _showOrderPicker,
                  child: const Text('更换订单', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _isOrderFromWidget ? null : _showOrderPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: _orderError != null ? Border.all(color: Colors.red) : null,
              ),
              child: hasOrder
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _orderDisplayText(_selectedOrder!),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _orderSubtitleText(_selectedOrder!),
                          style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                        ),
                        Builder(builder: (_) {
                          final amtText = _computeOrderTotalText(_selectedOrder!);
                          if (amtText.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '总价：$amtText',
                              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                          );
                        }),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 18, color: _orderError != null ? Colors.red : const Color(0xFFB0B8C9)),
                        const SizedBox(width: 8),
                        Text(
                          '请选择关联订单',
                          style: TextStyle(fontSize: 14, color: _orderError != null ? Colors.red : const Color(0xFFB0B8C9)),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, size: 18, color: _orderError != null ? Colors.red : const Color(0xFFB0B8C9)),
                      ],
                    ),
            ),
          ),
          if (_orderError != null) ...[
            const SizedBox(height: 6),
            Text(_orderError!, style: const TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ],
      ),
    );
  }

  void _showOrderPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _OrderPickerSheet(
        onSelect: (order) {
          Navigator.pop(ctx);
          setState(() {
            _selectedOrder = order;
            _orderError = null;
          });
          // 选择订单后立即检查是否已有处理中售后单
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkDuplicateAftersales(order);
          });
        },
      ),
    );
  }

  // ── Type card ──
  Widget _buildTypeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('问题类型', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showTypePicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: _typeError != null ? Colors.red : const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedType ?? '请选择问题类型',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _selectedType != null ? AppColors.darkText : const Color(0xFFB0B8C9),
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFFB0B8C9)),
                ],
              ),
            ),
          ),
          if (_typeError != null) ...[
            const SizedBox(height: 6),
            Text(_typeError!, style: const TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ],
      ),
    );
  }

  void _showTypePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text('选择问题类型', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText)),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _problemTypes.map((t) => ListTile(
                      title: Text(t, style: const TextStyle(fontSize: 15, color: AppColors.darkText)),
                      trailing: _selectedType == t ? const Icon(Icons.check, color: AppColors.primary, size: 20) : null,
                      onTap: () {
                        setState(() {
                          _selectedType = t;
                          _typeError = null;
                        });
                        Navigator.pop(ctx);
                      },
                    )).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Description card ──
  Widget _buildDescCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('问题描述', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText)),
              Text(' *', style: TextStyle(fontSize: 15, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 5,
            maxLength: 500,
            style: const TextStyle(fontSize: 14, color: AppColors.darkText),
            onChanged: (_) {
              if (_descError != null) setState(() => _descError = null);
            },
            decoration: InputDecoration(
              hintText: '请详细描述您遇到的问题...',
              hintStyle: TextStyle(fontSize: 14, color: AppColors.darkText.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _descError != null ? Colors.red : const Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _descError != null ? Colors.red : const Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          if (_descError != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(_descError!, style: const TextStyle(fontSize: 12, color: Colors.red)),
            ),
        ],
      ),
    );
  }

  // ── Upload card ──
  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('上传凭证', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText)),
              Text(' *', style: TextStyle(fontSize: 15, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._imageBytesList.asMap().entries.map((entry) => _buildImageThumb(entry.key, entry.value)),
              if (_imageBytesList.length < 6) _buildAddImageButton(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _imageError ?? '最多上传6张图片，支持JPG/PNG格式',
            style: TextStyle(fontSize: 11, color: _imageError != null ? Colors.red : const Color(0xFFB0B8C9)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumb(int index, Uint8List bytes) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.memory(
              bytes,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.background,
                child: const Center(child: Icon(Icons.broken_image, size: 28, color: AppColors.subtitle)),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() => _imageBytesList.removeAt(index));
              },
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _imageError != null ? Colors.red : const Color(0xFFE5E7EB),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 22, color: _imageError != null ? Colors.red : const Color(0xFFB0B8C9)),
            const SizedBox(height: 4),
            Text(
              '添加图片',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _imageError != null ? Colors.red : const Color(0xFFB0B8C9)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('拍照'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('从相册选择'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (source == null) return;

      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (picked == null || !mounted) return;

      // 跨平台读取字节流（Web + 移动端均可用，与聊天页一致）
      Uint8List bytes;
      try {
        bytes = await picked.readAsBytes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('读取图片失败：$e'), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      // 检查文件大小（10MB）
      if (bytes.length > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片大小不能超过10MB'), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      setState(() {
        _imageBytesList.add(bytes);
        _imageError = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败：$e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // ── Submit bar ──
  Widget _buildSubmitBar() {
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
          onPressed: _submitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
            disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          ),
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('提交申请', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  bool _validate() {
    bool valid = true;

    if (_selectedOrder == null) {
      _orderError = '请先选择关联订单';
      valid = false;
    } else {
      _orderError = null;
    }

    if (_selectedType == null) {
      _typeError = '请选择问题类型';
      valid = false;
    } else {
      _typeError = null;
    }

    if (_descController.text.trim().isEmpty) {
      _descError = '请描述您遇到的问题';
      valid = false;
    } else {
      _descError = null;
    }

    if (_imageBytesList.isEmpty) {
      _imageError = '请至少上传一张证据图片';
      valid = false;
    } else {
      _imageError = null;
    }

    setState(() {});
    return valid;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;
    setState(() => _submitting = true);

    try {
      final order = _selectedOrder!;
      final orderIdInt = (order['id'] as num).toInt();

      final provider = context.read<AftersalesProvider>();
      final service = context.read<AftersalesService>();

      // 防重复检查（加载最新缓存）
      await provider.ensureLoaded();
      if (!mounted) return;
      if (provider.isOrderAftersalesOpen(orderIdInt)) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该订单已有处理中售后单，不能重复创建'), backgroundColor: Colors.redAccent),
        );
        return;
      }

      // 上传图片 → 获取 URL 列表
      final imageUrls = <String>[];
      for (int i = 0; i < _imageBytesList.length; i++) {
        final url = await service.uploadEvidenceBytes(
          _imageBytesList[i],
          'evidence_$i.jpg',
        );
        imageUrls.add(url);
      }

      if (!mounted) return;

      // 提交售后记录到数据库
      final record = await provider.createAftersale(
        orderId: orderIdInt,
        type: _selectedType!,
        description: _descController.text.trim(),
        evidenceImages: imageUrls,
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投诉已提交'), backgroundColor: Color(0xFF00A63E)),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AftersalesDetailPage(aftersaleId: record['id'] as int),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失败：$e'), backgroundColor: Colors.redAccent),
      );
    }
  }
}

// ── Order Picker Bottom Sheet ──
class _OrderPickerSheet extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _OrderPickerSheet({required this.onSelect});

  @override
  State<_OrderPickerSheet> createState() => _OrderPickerSheetState();
}

class _OrderPickerSheetState extends State<_OrderPickerSheet> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final role = context.read<AuthProvider>().role;
      Map<String, dynamic> result;
      if (role == 'EMPLOYER') {
        result = await context.read<EmployerService>().listOrders();
      } else {
        result = await context.read<TranslatorService>().listOrders();
      }

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(result['list'] ?? []);
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

  String _statusLabel(String status) {
    const map = {
      'PENDING_QUOTE': '待报价',
      'PENDING_CONFIRM': '待确认',
      'CONFIRMED': '已确认',
      'IN_SERVICE': '服务中',
      'PENDING_EMPLOYER_CONFIRMATION': '待完成确认',
      'COMPLETED': '已完成',
      'CANCELLED': '已取消',
    };
    return map[status] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(width: 48),
                const Expanded(
                  child: Text(
                    '选择关联订单',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Text('加载失败', style: const TextStyle(color: AppColors.darkText, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(_error!, style: const TextStyle(color: AppColors.subtitle, fontSize: 12)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() { _isLoading = true; _error = null; });
                      _loadOrders();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          else if (_orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 40, color: AppColors.subtitle),
                    SizedBox(height: 8),
                    Text('暂无订单', style: TextStyle(color: AppColors.subtitle, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final order = _orders[index];
                  final orderNo = order['orderNo'] ?? 'ORD-${(order['id'] ?? 0).toString().padLeft(6, '0')}';
                  final status = order['status'] ?? '';
                  return GestureDetector(
                    onTap: () => widget.onSelect(order),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  orderNo,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.subtitle),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _statusLabel(status),
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            order['expoName'] ?? '',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order['dateRange'] ?? ''} · ${order['city'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                          ),
                          if ((order['quoteSummary'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '金额：${order['quoteSummary']}',
                              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
