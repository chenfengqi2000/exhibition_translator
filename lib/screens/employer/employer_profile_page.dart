import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'favorites_page.dart';
import 'employer_requests_page.dart';
import 'invoice_list_page.dart';
import 'invoice_info_page.dart';
import '../common/aftersales_list_page.dart';

class EmployerProfilePage extends StatelessWidget {
  final Function(int)? onSwitchTab;

  const EmployerProfilePage({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? '用户';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, userName),
            const SizedBox(height: 20),
            _buildMenuGroup(context, [
              _MenuItem(
                icon: Icons.business,
                title: '公司信息',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能开发中'))),
              ),
              _MenuItem(
                icon: Icons.receipt_outlined,
                title: '开票信息',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceInfoPage())),
              ),
              _MenuItem(
                icon: Icons.receipt_long,
                title: '我的发票',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceListPage())),
              ),
            ]),
            const SizedBox(height: 12),
            _buildMenuGroup(context, [
              _MenuItem(
                icon: Icons.description_outlined,
                title: '我的需求',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployerRequestsPage())),
              ),
              _MenuItem(
                icon: Icons.favorite_border,
                title: '我的收藏',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage())),
              ),
              _MenuItem(
                icon: Icons.receipt_long_outlined,
                title: '我的订单',
                onTap: () => onSwitchTab?.call(3),
              ),
              _MenuItem(
                icon: Icons.support_agent,
                title: '售后记录',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AftersalesListPage())),
              ),
            ]),
            const SizedBox(height: 12),
            _buildMenuGroup(context, [
              _MenuItem(
                icon: Icons.notifications_none,
                title: '通知设置',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能开发中'))),
              ),
              _MenuItem(
                icon: Icons.help_outline,
                title: '帮助与客服',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能开发中'))),
              ),
              _MenuItem(
                icon: Icons.lock_outline,
                title: '账号与安全',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能开发中'))),
              ),
            ]),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('退出登录'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              userName.isNotEmpty ? userName[0] : '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('雇主账户', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(BuildContext context, List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              if (index > 0) const Divider(height: 1, indent: 52, endIndent: 16),
              ListTile(
                leading: Icon(item.icon, color: AppColors.primary, size: 22),
                title: Text(item.title, style: const TextStyle(fontSize: 15, color: AppColors.darkText)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.subtitle, size: 20),
                onTap: item.onTap,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  _MenuItem({required this.icon, required this.title, this.onTap});
}
