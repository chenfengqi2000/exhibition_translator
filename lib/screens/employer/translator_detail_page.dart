import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/translator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/translator_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../services/review_service.dart';
import '../../services/chat_service.dart';
import '../../services/employer_service.dart';
import '../../widgets/state_widgets.dart';
import '../chat/chat_detail_page.dart';

class TranslatorDetailPage extends StatefulWidget {
  final Translator? translator;
  final String? translatorId;

  const TranslatorDetailPage({super.key, this.translator, this.translatorId})
      : assert(translator != null || translatorId != null);

  @override
  State<TranslatorDetailPage> createState() => _TranslatorDetailPageState();
}

class _TranslatorDetailPageState extends State<TranslatorDetailPage> {
  Translator? _translator;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> _reviews = [];
  int _reviewTotal = 0;
  bool _reviewsLoading = false;

  List<Map<String, dynamic>> _myRequests = [];
  bool _inviting = false;

  @override
  void initState() {
    super.initState();
    if (widget.translator != null) {
      _translator = widget.translator;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _translator != null && _translator!.isFavorited) {
          context.read<FavoriteProvider>().syncFromTranslatorList([_translator!]);
        }
        _fetchReviews();
        _loadMyRequests();
      });
    } else {
      _fetchDetail();
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final id = widget.translatorId ?? widget.translator!.id;
    final result = await context.read<TranslatorProvider>().loadTranslatorDetail(id);

    if (mounted) {
      setState(() {
        _translator = result;
        _isLoading = false;
        if (result == null) _error = '加载失败';
      });
      if (result != null) {
        _fetchReviews();
        _loadMyRequests();
      }
    }
  }

  Future<void> _fetchReviews() async {
    final tid = _translator?.id ?? widget.translatorId;
    if (tid == null) return;
    setState(() => _reviewsLoading = true);
    try {
      final service = context.read<ReviewService>();
      final result = await service.listTranslatorReviews(tid, pageSize: 5);
      if (mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(result['list'] ?? []);
          _reviewTotal = (result['total'] as num?)?.toInt() ?? 0;
          _reviewsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          '翻译员详情',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) {
      return ErrorRetryWidget(message: _error!, onRetry: _fetchDetail);
    }
    if (_translator == null) {
      return const EmptyWidget(message: '翻译员信息不存在');
    }

    final t = _translator!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(t),
                const SizedBox(height: 16),
                _buildInfoCard(icon: Icons.translate, label: '语言能力', value: t.languageLabel),
                const SizedBox(height: 12),
                _buildInfoCard(icon: Icons.work_outline, label: '服务类型', value: t.serviceTypes.isNotEmpty ? t.serviceTypes.join('、') : '-'),
                const SizedBox(height: 12),
                _buildInfoCard(icon: Icons.location_on_outlined, label: '服务城市', value: t.serviceCities.isNotEmpty ? t.serviceCities.join('、') : t.cityLabel),
                const SizedBox(height: 12),
                _buildInfoCard(icon: Icons.business_center_outlined, label: '擅长行业', value: t.industries.isNotEmpty ? t.industries.join('、') : '-'),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.payments_outlined,
                  label: '服务报价',
                  value: t.priceLabel,
                  valueColor: AppColors.primary,
                  valueBold: true,
                ),
                if (t.intro.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildIntroCard(t.intro),
                ],
                const SizedBox(height: 12),
                _buildReviewsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildBottomButtons(context),
      ],
    );
  }

  Widget _buildProfileHeader(Translator t) {
    final hasAvatar = t.avatar.isNotEmpty;
    final isVerified = t.auditStatus == 'APPROVED';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            backgroundImage: hasAvatar ? NetworkImage(t.avatar) : null,
            child: !hasAvatar
                ? Text(t.name.isNotEmpty ? t.name[0] : '', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))
                : null,
          ),
          const SizedBox(height: 12),
          Text(t.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
          if (isVerified) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 14, color: Color(0xFF00A63E)),
                  SizedBox(width: 4),
                  Text('已认证', style: TextStyle(fontSize: 12, color: Color(0xFF00A63E), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 18, color: Color(0xFFFFC107)),
              const SizedBox(width: 4),
              Text(t.ratingSummary.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.subtitle)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? AppColors.darkText,
                fontWeight: valueBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(String intro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('个人简介', style: TextStyle(fontSize: 14, color: AppColors.subtitle)),
          const SizedBox(height: 8),
          Text(intro, style: const TextStyle(fontSize: 14, color: AppColors.darkText)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFBBF24)),
              const SizedBox(width: 6),
              Text(
                '用户评价 ($_reviewTotal)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
              ),
            ],
          ),
          if (_reviewsLoading) ...[
            const SizedBox(height: 16),
            const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ] else if (_reviews.isEmpty) ...[
            const SizedBox(height: 12),
            const Text('暂无评价', style: TextStyle(color: AppColors.subtitle, fontSize: 14)),
          ] else ...[
            const SizedBox(height: 12),
            ..._reviews.map(_buildReviewItem),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final content = review['content'] as String? ?? '';
    final employerName = review['employerName'] as String? ?? '雇主';
    final createdAt = review['createdAt'] as int?;
    String dateStr = '';
    if (createdAt != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
      dateStr = '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.background,
                child: Icon(Icons.person, size: 16, color: AppColors.subtitle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  employerName.isNotEmpty ? employerName : '雇主',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkText),
                ),
              ),
              Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.subtitle)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                (i + 1) <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 16,
                color: (i + 1) <= rating ? const Color(0xFFFBBF24) : AppColors.border,
              );
            }),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(content, style: const TextStyle(fontSize: 13, color: AppColors.bodyText)),
          ],
          const SizedBox(height: 4),
          const Divider(color: AppColors.border, height: 1),
        ],
      ),
    );
  }

  Future<void> _openChat() async {
    final translatorUserId = int.tryParse(_translator?.id ?? '');
    if (translatorUserId == null) return;
    try {
      final chatService = context.read<ChatService>();
      final conv = await chatService.getOrCreateConversation(translatorUserId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(
              conversationId: (conv['id'] as num).toInt(),
              otherUserName: _translator?.name ?? '',
              otherUserId: translatorUserId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发起聊天失败: $e')));
      }
    }
  }

  Future<void> _loadMyRequests() async {
    final role = context.read<AuthProvider>().role;
    if (role != 'EMPLOYER') return;
    try {
      final service = context.read<EmployerService>();
      final result = await service.listRequests(pageSize: 20);
      if (mounted) {
        final all = List<Map<String, dynamic>>.from(result['list'] ?? []);
        // 仅保留可邀请报价的需求（排除已关闭和已取消）
        setState(() {
          _myRequests = all.where((r) {
            final status = r['requestStatus'] as String? ?? '';
            return status != 'CLOSED' && status != 'CANCELLED';
          }).toList();
        });
      }
    } catch (_) {}
  }

  void _showDemandPickerForInvite() {
    if (_myRequests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可邀请的需求（已关闭的需求无法邀请），请先发布需求')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _InviteDemandPickerSheet(
        requests: _myRequests,
        onSelect: _inviteToQuote,
      ),
    );
  }

  Future<void> _inviteToQuote(Map<String, dynamic> req) async {
    Navigator.pop(context); // 关闭底部弹窗

    final translatorUserId = int.tryParse(_translator?.id ?? '');
    if (translatorUserId == null) return;

    setState(() => _inviting = true);
    try {
      final chatService = context.read<ChatService>();

      // 1. 获取或创建会话
      final conv = await chatService.getOrCreateConversation(translatorUserId);
      final convId = (conv['id'] as num).toInt();

      // 2. 发送邀请文案消息
      final translatorName = _translator?.name ?? '翻译员';
      final expoName = req['expoName'] as String? ?? '翻译需求';
      await chatService.sendMessage(
        convId,
        content: '您好$translatorName，我有一个翻译需求「$expoName」，想邀请您报价，请查看以下需求详情：',
      );

      // 3. 发送需求卡片
      final reqId = (req['id'] as num?)?.toInt();
      await chatService.sendMessage(
        convId,
        msgType: 'DEMAND_CARD',
        content: '',
        refRequestId: reqId,
      );

      // 4. 跳转到聊天详情页
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(
              conversationId: convId,
              otherUserName: translatorName,
              otherUserId: translatorUserId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('邀请报价失败：$e')),
        );
      }
    }
    if (mounted) setState(() => _inviting = false);
  }

  Widget _buildBottomButtons(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    final isEmployer = role == 'EMPLOYER';

    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (isEmployer) ...[
            Consumer<FavoriteProvider>(
              builder: (context, favProvider, _) {
                final translatorId = _translator?.id ?? '';
                final favorited = favProvider.isFavorited(translatorId);
                return SizedBox(
                  width: 56,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: translatorId.isEmpty
                        ? null
                        : () => favProvider.toggleFavorite(translatorId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: favorited ? const Color(0xFFEF4444) : AppColors.primary,
                      side: BorderSide(color: favorited ? const Color(0xFFEF4444) : AppColors.primary),
                      shape: const StadiumBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(
                      favorited ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: favorited ? const Color(0xFFEF4444) : AppColors.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isEmployer ? _openChat : null,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('立即沟通'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: const StadiumBorder(),
                  minimumSize: const Size(0, 48),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: isEmployer && !_inviting ? _showDemandPickerForInvite : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  minimumSize: const Size(0, 48),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: _inviting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('邀请报价'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 邀请报价 - 需求选择器
class _InviteDemandPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final Function(Map<String, dynamic>) onSelect;

  const _InviteDemandPickerSheet({required this.requests, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '选择需求邀请报价',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 4),
          const Text(
            '将自动发送邀请消息和需求卡片给翻译员',
            style: TextStyle(fontSize: 13, color: AppColors.subtitle),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final req = requests[index];
                return _buildRequestItem(context, req);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(BuildContext context, Map<String, dynamic> req) {
    final expoName = req['expoName'] as String? ?? '';
    final city = req['city'] as String? ?? '';
    final dateRange = req['dateRange'] as String? ?? '';

    return InkWell(
      onTap: () => onSelect(req),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expoName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$city · $dateRange',
                    style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                  ),
                ],
              ),
            ),
            const Icon(Icons.send, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
