import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/employer_service.dart';
import '../translator/opportunity_detail_page.dart';
import '../common/order_detail_page.dart';

class ChatDetailPage extends StatefulWidget {
  final int conversationId;
  final String otherUserName;
  final int otherUserId;

  const ChatDetailPage({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _sending = false;
  bool _uploading = false;

  // 雇主的需求列表（用于发送需求卡片）
  List<Map<String, dynamic>> _myRequests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
      _loadMyRequests();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<ChatService>();
      final result = await service.listMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(result['list'] ?? []);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMyRequests() async {
    final role = context.read<AuthProvider>().role;
    if (role != 'EMPLOYER') return;
    try {
      final service = context.read<EmployerService>();
      final result = await service.listRequests(pageSize: 10);
      if (mounted) {
        setState(() {
          _myRequests = List<Map<String, dynamic>>.from(result['list'] ?? []);
        });
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final service = context.read<ChatService>();
      await service.sendMessage(widget.conversationId, content: text);
      _controller.clear();
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('消息发送失败：$e')),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _sendDemandCard(Map<String, dynamic> req) async {
    setState(() => _sending = true);
    try {
      final service = context.read<ChatService>();
      final reqId = (req['id'] as num?)?.toInt();
      await service.sendMessage(
        widget.conversationId,
        msgType: 'DEMAND_CARD',
        content: '',
        refRequestId: reqId,
      );
      await _loadMessages();
      if (mounted) Navigator.pop(context); // 关闭底部弹窗
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('需求卡片发送失败：$e')),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _pickAndSendImage() async {
    if (_uploading || _sending) return;

    XFile? picked;
    try {
      picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败：$e')),
        );
      }
      return;
    }
    if (picked == null || !mounted) return;

    // 读取字节流（跨平台：Web + 移动端均可用）
    Uint8List bytes;
    try {
      bytes = await picked.readAsBytes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取图片失败：$e')),
        );
      }
      return;
    }

    // 检查文件大小（10MB）
    if (bytes.length > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片不能超过 10MB')),
        );
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      final service = context.read<ChatService>();
      await service.sendImageMessage(
        widget.conversationId,
        bytes: bytes,
        fileName: picked.name,
      );
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片发送失败：$e')),
        );
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  void _showDemandPicker() {
    if (_myRequests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可分享的需求，请先发布需求')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _DemandPickerSheet(
        requests: _myRequests,
        onSelect: _sendDemandCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final role = context.read<AuthProvider>().role;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.otherUserName,
          style: const TextStyle(
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('暂无消息', style: TextStyle(color: AppColors.subtitle)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMine = (msg['senderId'] as num?)?.toInt().toString() == currentUserId;
                          return _buildMessageBubble(msg, isMine);
                        },
                      ),
          ),
          _buildInputBar(role),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMine) {
    final msgType = msg['msgType'] as String? ?? 'TEXT';
    final content = msg['content'] as String? ?? '';

    if (msgType == 'DEMAND_CARD') {
      return _buildDemandCardBubble(content, isMine);
    }

    if (msgType == 'IMAGE') {
      return _buildImageBubble(msg, isMine);
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMine ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: isMine ? Colors.white : AppColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildDemandCardBubble(String contentJson, bool isMine) {
    Map<String, dynamic> card = {};
    try {
      card = Map<String, dynamic>.from(jsonDecode(contentJson));
    } catch (_) {
      return _buildMessageBubble({'content': '[需求卡片]', 'msgType': 'TEXT'}, isMine);
    }

    final requestId = (card['requestId'] as num?)?.toInt();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          if (requestId == null) return;
          final role = context.read<AuthProvider>().role;
          if (role == 'TRANSLATOR') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OpportunityDetailPage(requestId: requestId),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailPage(requestId: requestId, isEmployer: true),
              ),
            );
          }
        },
        child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text(
                  '翻译需求',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              card['expoName'] ?? '',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            const SizedBox(height: 6),
            _cardInfoRow(Icons.calendar_today_outlined, '${card['dateStart'] ?? ''} ~ ${card['dateEnd'] ?? ''}'),
            const SizedBox(height: 4),
            _cardInfoRow(Icons.translate, (card['languagePairs'] as List?)?.join('、') ?? ''),
            const SizedBox(height: 4),
            _cardInfoRow(Icons.location_on_outlined, '${card['city'] ?? ''} ${card['venue'] ?? ''}'),
            if (card['budgetMinAed'] != null && card['budgetMaxAed'] != null) ...[
              const SizedBox(height: 4),
              _cardInfoRow(
                Icons.payments_outlined,
                'AED ${(card['budgetMinAed'] as num).toInt()} - ${(card['budgetMaxAed'] as num).toInt()}',
              ),
            ],
            if (requestId != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '点击查看详情 →',
                    style: TextStyle(fontSize: 11, color: AppColors.primary.withOpacity(0.7)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildImageBubble(Map<String, dynamic> msg, bool isMine) {
    final imageUrl = msg['imageUrl'] as String?;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildMessageBubble({'content': '[图片加载失败]', 'msgType': 'TEXT'}, isMine);
    }

    // 构建完整 URL：后端返回的是相对路径 /uploads/chat_images/xxx.jpg
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api/v1', '');
    final fullUrl = '$baseUrl$imageUrl';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _showFullImage(context, fullUrl),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 260),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMine ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMine ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(16),
            ),
            child: Image.network(
              fullUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 160,
                  height: 120,
                  color: Colors.grey[200],
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 160,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined, color: Colors.grey, size: 28),
                      SizedBox(height: 4),
                      Text('图片加载失败', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(
              url,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _cardInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.subtitle),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.bodyText),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar(String? role) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 雇主可发送需求卡片
          if (role == 'EMPLOYER')
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 26),
              onPressed: _showDemandPicker,
              tooltip: '发送需求卡片',
            ),
          // 双方均可发送图片
          _uploading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.image_outlined, color: AppColors.primary, size: 24),
                    onPressed: _pickAndSendImage,
                    tooltip: '发送图片',
                  ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '输入消息...',
                  hintStyle: TextStyle(color: AppColors.subtitle, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendText(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(
              Icons.send_rounded,
              color: _sending ? AppColors.subtitle : AppColors.primary,
              size: 26,
            ),
            onPressed: _sending ? null : _sendText,
          ),
        ],
      ),
    );
  }
}

/// 需求选择器 BottomSheet
class _DemandPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final Function(Map<String, dynamic>) onSelect;

  const _DemandPickerSheet({required this.requests, required this.onSelect});

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
            '选择需求卡片发送',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 4),
          const Text(
            '将需求信息分享给翻译员，方便沟通',
            style: TextStyle(fontSize: 13, color: AppColors.subtitle),
          ),
          const SizedBox(height: 16),
          Flexible(
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
