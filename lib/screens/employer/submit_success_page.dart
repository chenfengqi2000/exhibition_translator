import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common/order_detail_page.dart';

class SubmitSuccessPage extends StatelessWidget {
  final int requestId;

  const SubmitSuccessPage({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 24),
              const Text(
                '需求已提交',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText),
              ),
              const SizedBox(height: 12),
              const Text(
                '平台将审核你的需求，审核通过后请等待翻译报价',
                style: TextStyle(fontSize: 14, color: AppColors.subtitle),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailPage(
                          requestId: requestId,
                          isEmployer: true,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: const Text('查看需求详情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('返回首页', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
