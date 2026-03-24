import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'translator_workspace_page.dart';
import 'translator_schedule_page.dart';
import 'translator_orders_page.dart';
import 'translator_profile_page.dart';
import '../chat/chat_list_page.dart';

class TranslatorMainPage extends StatefulWidget {
  const TranslatorMainPage({super.key});

  @override
  State<TranslatorMainPage> createState() => _TranslatorMainPageState();
}

class _TranslatorMainPageState extends State<TranslatorMainPage> {
  int _currentIndex = 0;

  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  late final List<Widget> _pages = [
    TranslatorWorkspacePage(onSwitchTab: (index) => setState(() => _currentIndex = index)),
    const TranslatorSchedulePage(),
    const ChatListPage(),
    const TranslatorOrdersPage(),
    TranslatorProfilePage(onSwitchTab: (index) => setState(() => _currentIndex = index)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.subtitle,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: '工作台',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: '档期',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: '聊天',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: '订单',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
