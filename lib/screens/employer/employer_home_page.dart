import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/translator_provider.dart';
import '../../widgets/translator_card.dart';
import '../../widgets/state_widgets.dart';
import 'submit_demand_page.dart';
import 'translator_detail_page.dart';
import 'employer_requests_page.dart';
import '../common/notification_list_page.dart';
import '../../services/notification_service.dart';

class EmployerHomePage extends StatefulWidget {
  final Function(int)? onSwitchTab;

  const EmployerHomePage({super.key, this.onSwitchTab});

  @override
  State<EmployerHomePage> createState() => _EmployerHomePageState();
}

class _EmployerHomePageState extends State<EmployerHomePage> {
  @override
  void initState() {
    super.initState();
    // 首页加载推荐翻译列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TranslatorProvider>().loadTranslators();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? '用户';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, userName),
            const SizedBox(height: 20),
            // 常用展馆
            _SectionHeader(
              title: '常用展馆',
              onViewAll: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('查看全部展馆功能开发中')),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _VenueCard(name: 'DWTC', fullName: '迪拜世界贸易中心', icon: Icons.location_city),
                  SizedBox(width: 12),
                  _VenueCard(name: 'ADNEC', fullName: '阿布扎比国家展览中心', icon: Icons.account_balance),
                  SizedBox(width: 12),
                  _VenueCard(name: 'DIEC', fullName: '迪拜国际展览中心', icon: Icons.domain),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 推荐翻译
            _SectionHeader(
              title: '推荐翻译',
              onViewAll: () => widget.onSwitchTab?.call(1),
            ),
            const SizedBox(height: 12),
            _buildTranslatorList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslatorList() {
    return Consumer<TranslatorProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const SizedBox(height: 200, child: LoadingWidget());
        }
        if (provider.error != null) {
          return SizedBox(
            height: 240,
            child: ErrorRetryWidget(
              message: provider.error!,
              onRetry: () => provider.loadTranslators(),
            ),
          );
        }
        if (provider.translators.isEmpty) {
          return const SizedBox(
            height: 200,
            child: EmptyWidget(message: '暂无推荐翻译'),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: provider.translators.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final translator = provider.translators[index];
            return TranslatorCard(
              translator: translator,
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
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '欢迎回来',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: _NotificationBell(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit_note,
                  label: '发布翻译需求',
                  isWhite: true,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitDemandPage()));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.description_outlined,
                  label: '我的需求',
                  isWhite: false,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployerRequestsPage())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isWhite,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isWhite ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isWhite ? AppColors.primary : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isWhite ? AppColors.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.darkText)),
          GestureDetector(
            onTap: onViewAll,
            child: const Text('查看全部', style: TextStyle(fontSize: 13, color: AppColors.subtitle)),
          ),
        ],
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final String name;
  final String fullName;
  final IconData icon;
  const _VenueCard({required this.name, required this.fullName, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const Spacer(),
          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText)),
          const SizedBox(height: 2),
          Text(fullName, style: const TextStyle(fontSize: 11, color: AppColors.subtitle), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// 通知铃铛 + 未读红点
class _NotificationBell extends StatefulWidget {
  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    try {
      final service = context.read<NotificationService>();
      final count = await service.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationListPage()),
            );
            _loadUnread();
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
