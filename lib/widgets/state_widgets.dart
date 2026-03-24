import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 加载中
class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: AppColors.subtitle, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

/// 加载失败，支持重试
class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetryWidget({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.subtitle.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppColors.subtitle, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空数据
class EmptyWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyWidget({
    super.key,
    this.message = '暂无数据',
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.subtitle.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.subtitle, fontSize: 15)),
        ],
      ),
    );
  }
}
