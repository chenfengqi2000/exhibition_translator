import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    await auth.register(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (auth.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error!)),
        );
        auth.clearError();
      } else {
        // 注册成功：显示提示 + 自动 pop 回登录页
        // main.dart 的 Consumer 会自动根据 isLoggedIn=true 且 role=null 显示身份选择页
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注册成功！请选择您的身份')),
        );
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // Logo
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.language, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    '创建账号',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    '注册展会翻译，开启专业服务',
                    style: TextStyle(fontSize: 14, color: AppColors.subtitle),
                  ),
                ),
                const SizedBox(height: 36),

                // 姓名
                _buildLabel('姓名'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    hintText: '请输入您的姓名',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '请输入姓名';
                    if (v.trim().length < 2) return '姓名至少 2 个字符';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 手机号
                _buildLabel('手机号'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    hintText: '请输入手机号',
                    prefixIcon: Icons.phone_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '请输入手机号';
                    if (v.trim().length < 8) return '请输入有效的手机号';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 密码
                _buildLabel('密码'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    hintText: '请设置密码（至少 6 位）',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _eyeButton(
                      obscure: _obscurePassword,
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '请设置密码';
                    if (v.length < 6) return '密码至少 6 位';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 确认密码
                _buildLabel('确认密码'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  decoration: _inputDecoration(
                    hintText: '再次输入密码',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _eyeButton(
                      obscure: _obscureConfirm,
                      onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '请再次输入密码';
                    if (v != _passwordController.text) return '两次密码不一致';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // 注册按钮
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _handleRegister,
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
                            '注册',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // 返回登录
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '已有账号？',
                        style: TextStyle(fontSize: 14, color: AppColors.subtitle),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          '立即登录',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
    );
  }

  Widget _eyeButton({required bool obscure, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.subtitle,
        size: 20,
      ),
      onPressed: onTap,
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.subtitle, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: AppColors.subtitle, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
