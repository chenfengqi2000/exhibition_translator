import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'translator_info_page.dart';
import 'my_reviews_page.dart';
import '../common/aftersales_list_page.dart';

class TranslatorProfilePage extends StatelessWidget {
  final Function(int)? onSwitchTab;

  const TranslatorProfilePage({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildMenuGroup([
              _MenuItem(Icons.person_outline, '个人资料', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslatorInfoPage()));
              }),
              _MenuItem(Icons.star_rounded, '评价中心', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsPage()));
              }),
              _MenuItem(Icons.verified_outlined, '资质证书', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能开发中')));
              }),
            ]),
            const SizedBox(height: 14),
            _buildMenuGroup([
              _MenuItem(Icons.receipt_long_outlined, '我的订单', onTap: () {
                onSwitchTab?.call(3);
              }),
              _MenuItem(Icons.account_balance_wallet_outlined, '收入明细', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能开发中')));
              }),
              _MenuItem(Icons.support_agent, '售后记录', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AftersalesListPage()));
              }),
            ]),
            const SizedBox(height: 14),
            _buildMenuGroup([
              _MenuItem(Icons.notifications_outlined, '通知设置', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能开发中')));
              }),
              _MenuItem(Icons.help_outline, '帮助与客服', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能开发中')));
              }),
              _MenuItem(Icons.security_outlined, '账号与安全', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能开发中')));
              }),
            ]),
            const SizedBox(height: 28),
            _buildLogoutButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? '用户';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF3B5AE0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0] : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '翻译员账户',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Column(
              children: [
                InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.vertical(
                    top: index == 0
                        ? const Radius.circular(14)
                        : Radius.zero,
                    bottom: index == items.length - 1
                        ? const Radius.circular(14)
                        : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            color: AppColors.primary,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              color: AppColors.darkText,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.subtitle.withOpacity(0.5),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                if (index < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 66),
                    child: Divider(
                      height: 1,
                      color: Colors.grey.withOpacity(0.1),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: () {
            context.read<AuthProvider>().logout();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFF4757),
            side: const BorderSide(color: Color(0xFFFF4757), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            '退出登录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _MenuItem(this.icon, this.label, {this.onTap});
}
