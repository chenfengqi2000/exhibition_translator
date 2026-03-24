import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  int _selectedRole = 0; // 0: employer, 1: translator
  bool _submitting = false;

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    final role = _selectedRole == 0 ? 'EMPLOYER' : 'TRANSLATOR';
    try {
      await context.read<AuthProvider>().setRole(role);
      if (mounted) {
        // 角色设置成功，显示提示后自动导航
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已选择${_selectedRole == 0 ? '雇主' : '翻译员'}身份')),
        );
        // 不需要手动导航，main.dart 的 Consumer 会自动路由
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置角色失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.language, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),
              const Text(
                '选择您的身份',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '请选择您在平台中的角色，以便为您提供专属服务',
                style: TextStyle(fontSize: 14, color: AppColors.subtitle),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildRoleCard(
                index: 0,
                icon: Icons.business_center,
                title: '我是雇主',
                description: '我需要为展会寻找专业翻译，发布需求、筛选译员、管理订单',
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                index: 1,
                icon: Icons.translate,
                title: '我是翻译员',
                description: '我是专业翻译，希望接展会翻译订单、管理档期、跟踪履约',
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '确认进入',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required int index,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final bool isSelected = _selectedRole == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.subtitle,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.subtitle,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
