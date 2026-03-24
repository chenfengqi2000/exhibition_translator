import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/chat_service.dart';
import 'chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    final query = _searchQuery.toLowerCase();
    return _conversations.where((conv) {
      final name = (conv['otherUserName'] as String? ?? '').toLowerCase();
      final lastMsg = (conv['lastMessage'] as String? ?? '').toLowerCase();
      return name.contains(query) || lastMsg.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<ChatService>();
      final result = await service.listConversations();
      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(result['list'] ?? []);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChat(Map<String, dynamic> conv) {
    final convId = (conv['id'] as num?)?.toInt() ?? 0;
    final otherUserId = (conv['otherUserId'] as num?)?.toInt() ?? 0;
    final name = conv['otherUserName'] as String? ?? '';
    final isKefu = conv['isCustomerService'] == true;

    if (isKefu && convId == 0) {
      // 客服虚拟条目 — 先创建会话
      _openKefuChat();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          conversationId: convId,
          otherUserName: name,
          otherUserId: otherUserId,
        ),
      ),
    ).then((_) => _loadConversations());
  }

  Future<void> _openKefuChat() async {
    try {
      final service = context.read<ChatService>();
      final conv = await service.getOrCreateConversation(0);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(
              conversationId: (conv['id'] as num).toInt(),
              otherUserName: '客服',
              otherUserId: 0,
            ),
          ),
        ).then((_) => _loadConversations());
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredConversations;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + search area
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
                const Text(
                  '聊天',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 12),
                // Search box
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(fontSize: 14, color: AppColors.darkText),
                    decoration: InputDecoration(
                      hintText: '搜索会话',
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.subtitle),
                      prefixIcon: const Icon(Icons.search, color: AppColors.subtitle, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              child: const Icon(Icons.clear, color: AppColors.subtitle, size: 18),
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
          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadConversations,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.subtitle),
                                  SizedBox(height: 12),
                                  Text('暂无会话', style: TextStyle(color: AppColors.subtitle, fontSize: 15)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 16),
                          itemBuilder: (context, index) {
                            final conv = filtered[index];
                            return _buildConversationTile(conv);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conv) {
    final name = conv['otherUserName'] as String? ?? '';
    final lastMsg = conv['lastMessage'] as String? ?? '';
    final unread = (conv['unreadCount'] as num?)?.toInt() ?? 0;
    final isKefu = conv['isCustomerService'] == true;
    final lastAt = (conv['lastMessageAt'] as num?)?.toInt() ?? 0;

    String timeStr = '';
    if (lastAt > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(lastAt * 1000);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        timeStr = '${dt.month}/${dt.day}';
      }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: isKefu ? const Color(0xFF00C48C) : AppColors.primary,
        child: Icon(
          isKefu ? Icons.headset_mic : Icons.person,
          color: Colors.white,
          size: 22,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(timeStr, style: const TextStyle(fontSize: 12, color: AppColors.subtitle)),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMsg,
              style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (unread > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4757),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      onTap: () => _openChat(conv),
    );
  }
}
