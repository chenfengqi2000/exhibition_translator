import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/translator_service.dart';
import '../../services/availability_service.dart';
import 'new_demands_page.dart';
import 'translator_info_page.dart';
import 'translator_quotes_page.dart';
import '../common/notification_list_page.dart';
import '../../services/notification_service.dart';

// ── 订单状态辅助 ──────────────────────────────────────────────────
String _orderStatusLabel(String s) {
  switch (s) {
    case 'PENDING_CONFIRM':
      return '待确认';
    case 'CONFIRMED':
      return '已确认';
    case 'IN_SERVICE':
      return '服务中';
    case 'PENDING_EMPLOYER_CONFIRMATION':
      return '待完成确认';
    default:
      return s;
  }
}

Color _orderStatusColor(String s) {
  switch (s) {
    case 'PENDING_CONFIRM':
      return const Color(0xFFFFAA00);
    case 'CONFIRMED':
      return const Color(0xFF4A6CF7);
    case 'IN_SERVICE':
      return const Color(0xFF00C48C);
    case 'PENDING_EMPLOYER_CONFIRMATION':
      return const Color(0xFFFFAA00);
    default:
      return const Color(0xFF94A3B8);
  }
}

// ══════════════════════════════════════════════════════════════════
// 工作台页面
// ══════════════════════════════════════════════════════════════════

class TranslatorWorkspacePage extends StatefulWidget {
  final Function(int)? onSwitchTab;

  const TranslatorWorkspacePage({super.key, this.onSwitchTab});

  @override
  State<TranslatorWorkspacePage> createState() =>
      _TranslatorWorkspacePageState();
}

class _TranslatorWorkspacePageState extends State<TranslatorWorkspacePage> {
  List<Map<String, dynamic>> _latestDemands = [];
  List<Map<String, dynamic>> _recentOrders = [];
  bool _demandsLoading = true;
  bool _scheduleLoading = true;

  // ── 统计卡片 ──
  int _pendingQuote = 0;
  int _pendingConfirm = 0;
  int _todayService = 0;
  int _weekOrders = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
      _loadDemands();
      _loadRecentOrders();
    });
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final service = context.read<TranslatorService>();
      final data = await service.getDashboardStats();
      if (mounted) {
        setState(() {
          _pendingQuote = (data['pendingQuote'] as num?)?.toInt() ?? 0;
          _pendingConfirm = (data['pendingConfirm'] as num?)?.toInt() ?? 0;
          _todayService = (data['todayService'] as num?)?.toInt() ?? 0;
          _weekOrders = (data['weekOrders'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {
      // 未审核等情况静默处理，保持 0
    }
    if (mounted) setState(() => _statsLoading = false);
  }

  Future<void> _loadDemands() async {
    setState(() => _demandsLoading = true);
    try {
      final service = context.read<TranslatorService>();
      final result = await service.listOpportunities(pageSize: 2);
      final list = (result['list'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      if (mounted) setState(() => _latestDemands = list);
    } catch (_) {
      // 未审核通过时 API 会返回 403，静默处理
    }
    if (mounted) setState(() => _demandsLoading = false);
  }

  Future<void> _loadRecentOrders() async {
    setState(() => _scheduleLoading = true);
    try {
      final service = context.read<AvailabilityService>();
      final now = DateTime.now();
      final data =
          await service.getAvailability(year: now.year, month: now.month);
      final orders = (data['recentOrders'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      // 取前 2 条（后端已按 dateStart 升序排列）
      if (mounted) {
        setState(() => _recentOrders = orders.take(2).toList());
      }
    } catch (_) {}
    if (mounted) setState(() => _scheduleLoading = false);
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadStats(), _loadDemands(), _loadRecentOrders()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 20),
              _buildRecentSchedule(context),
              const SizedBox(height: 20),
              _buildLatestDemands(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final userName = context.watch<AuthProvider>().user?.name ?? '用户';
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _TranslatorNotificationBell(),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatCard(
                    _statsLoading ? '-' : '$_pendingQuote',
                    '待报价',
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    _statsLoading ? '-' : '$_pendingConfirm',
                    '待确认',
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    _statsLoading ? '-' : '$_todayService',
                    '今日服务',
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    _statsLoading ? '-' : '$_weekOrders',
                    '本周订单',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String number, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 快捷操作 ──────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildActionButton(
            Icons.description_outlined,
            '查看新需求',
            const Color(0xFF4A6CF7),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NewDemandsPage()));
            },
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            Icons.format_quote_outlined,
            '报价',
            const Color(0xFF00C48C),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TranslatorQuotesPage()));
            },
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            Icons.person_outline,
            '完善资料',
            const Color(0xFFFF8C42),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TranslatorInfoPage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
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
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 近期档期（真实数据） ──────────────────────────────────────

  Widget _buildRecentSchedule(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '近期档期',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => widget.onSwitchTab?.call(1),
                child: const Text(
                  '管理',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_scheduleLoading)
            _buildLoadingCard()
          else if (_recentOrders.isEmpty)
            _buildEmptyCard('暂无近期安排')
          else
            ..._recentOrders.map(_buildScheduleCard),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> order) {
    final expoName = order['expoName'] as String? ?? '';
    final dateStart = order['dateStart'] as String? ?? '';
    final dateEnd = order['dateEnd'] as String? ?? '';
    final venue = order['venue'] as String? ?? '';
    final orderStatus = order['orderStatus'] as String? ?? '';

    final statusLabel = _orderStatusLabel(orderStatus);
    final statusClr = _orderStatusColor(orderStatus);

    return GestureDetector(
      onTap: () => widget.onSwitchTab?.call(3),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: statusClr,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          expoName,
                          style: const TextStyle(
                            color: AppColors.darkText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusClr.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusClr,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppColors.subtitle),
                    const SizedBox(width: 4),
                    Text('$dateStart ~ $dateEnd',
                        style: const TextStyle(
                            color: AppColors.subtitle, fontSize: 13)),
                  ]),
                  if (venue.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.subtitle),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(venue,
                            style: const TextStyle(
                                color: AppColors.subtitle, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 最新需求（真实数据） ──────────────────────────────────────

  Widget _buildLatestDemands(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最新需求',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NewDemandsPage()));
                },
                child: const Text(
                  '查看全部',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_demandsLoading)
            _buildLoadingCard()
          else if (_latestDemands.isEmpty)
            _buildEmptyCard('暂无最新需求')
          else
            ..._latestDemands
                .map((d) => _buildRealDemandCard(context, d)),
        ],
      ),
    );
  }

  Widget _buildRealDemandCard(
      BuildContext context, Map<String, dynamic> demand) {
    final expoName = demand['expoName'] as String? ?? '';
    final dateStart = demand['dateStart'] as String? ?? '';
    final dateEnd = demand['dateEnd'] as String? ?? '';
    final langList = demand['languagePairs'] as List? ?? [];
    final langStr = langList.join('、');
    final translationType = demand['translationType'] as String? ?? '';
    final city = demand['city'] as String? ?? '';
    final venue = demand['venue'] as String? ?? '';
    final location = venue.isNotEmpty ? venue : city;

    // 紧急：开始日期在 3 天内
    bool isUrgent = false;
    if (dateStart.isNotEmpty) {
      try {
        final start = DateTime.parse(dateStart);
        isUrgent = start.difference(DateTime.now()).inDays <= 3;
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const NewDemandsPage()));
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    expoName,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '紧急',
                      style: TextStyle(
                        color: Color(0xFFFF4757),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDemandInfoRow(
                Icons.calendar_today_outlined, '$dateStart ~ $dateEnd'),
            const SizedBox(height: 6),
            _buildDemandInfoRow(Icons.translate, langStr),
            if (translationType.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildDemandInfoRow(Icons.work_outline, translationType),
            ],
            if (location.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildDemandInfoRow(Icons.location_on_outlined, location),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDemandInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.subtitle),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.subtitle, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── 公共辅助 ──────────────────────────────────────────────────

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(text,
            style: const TextStyle(color: AppColors.subtitle, fontSize: 14)),
      ),
    );
  }
}

/// 翻译员工作台通知铃铛
class _TranslatorNotificationBell extends StatefulWidget {
  @override
  State<_TranslatorNotificationBell> createState() => _TranslatorNotificationBellState();
}

class _TranslatorNotificationBellState extends State<_TranslatorNotificationBell> {
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
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationListPage()),
        );
        _loadUnread();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
            ),
            if (_unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4757),
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
        ),
      ),
    );
  }
}
