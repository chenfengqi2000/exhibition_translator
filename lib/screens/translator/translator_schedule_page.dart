import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/availability_service.dart';
import '../../widgets/state_widgets.dart';

// ── 状态颜色 & 标签 ─────────────────────────────────────────────
const _kAvailableColor = Color(0xFF00C48C);
const _kOccupiedColor = Color(0xFF4A6CF7);
const _kPendingColor = Color(0xFFFFAA00);
const _kRestColor = Color(0xFF94A3B8);

Color _statusColor(String status) {
  switch (status) {
    case 'AVAILABLE':
      return _kAvailableColor;
    case 'OCCUPIED':
      return _kOccupiedColor;
    case 'PENDING_CONFIRM':
      return _kPendingColor;
    case 'REST':
      return _kRestColor;
    default:
      return _kAvailableColor;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'AVAILABLE':
      return '可接单';
    case 'OCCUPIED':
      return '已占用';
    case 'PENDING_CONFIRM':
      return '待确认';
    case 'REST':
      return '休息';
    default:
      return status;
  }
}

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
      return _kPendingColor;
    case 'CONFIRMED':
      return _kOccupiedColor;
    case 'IN_SERVICE':
      return _kAvailableColor;
    case 'PENDING_EMPLOYER_CONFIRMATION':
      return _kPendingColor;
    default:
      return _kRestColor;
  }
}

const _kWeekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
const _kWeekdayFull = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

// ══════════════════════════════════════════════════════════════════
// 主页面
// ══════════════════════════════════════════════════════════════════

class TranslatorSchedulePage extends StatefulWidget {
  const TranslatorSchedulePage({super.key});

  @override
  State<TranslatorSchedulePage> createState() => _TranslatorSchedulePageState();
}

class _TranslatorSchedulePageState extends State<TranslatorSchedulePage> {
  late int _year;
  late int _month;
  String? _selectedDate;

  Map<String, dynamic> _slots = {};
  List<Map<String, dynamic>> _recentOrders = [];
  List<String> _serviceCities = [];
  List<String> _serviceVenues = [];
  List<int> _restWeekdays = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _selectedDate = _isoDate(now);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final service = context.read<AvailabilityService>();
      final data = await service.getAvailability(year: _year, month: _month);

      final slotsRaw = data['slots'] as Map<String, dynamic>? ?? {};
      final slots = <String, dynamic>{};
      slotsRaw.forEach((k, v) {
        slots[k] = Map<String, dynamic>.from(v as Map);
      });

      final orders = (data['recentOrders'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      final profile = data['profile'] as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
          _slots = slots;
          _recentOrders = orders;
          _serviceCities = List<String>.from(profile['serviceCities'] ?? []);
          _serviceVenues = List<String>.from(profile['serviceVenues'] ?? []);
          _restWeekdays = List<int>.from(
              (profile['restWeekdays'] as List?)?.map((e) => (e as num).toInt()) ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
    _loadData();
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _year = now.year;
      _month = now.month;
      _selectedDate = _isoDate(now);
    });
    _loadData();
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('我的档期',
            style: TextStyle(color: AppColors.darkText, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _openBatchSet,
            icon: const Icon(Icons.edit_calendar, size: 18),
            label: const Text('批量设置', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: '加载档期...')
          : _error != null
              ? ErrorRetryWidget(message: _error!, onRetry: _loadData)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMonthHeader(),
                        _buildWeekdayRow(),
                        _buildCalendarGrid(),
                        if (_selectedDate != null) _buildSelectedDayInfo(),
                        const SizedBox(height: 4),
                        _buildLegend(),
                        const SizedBox(height: 16),
                        _buildRecentSchedule(),
                        const SizedBox(height: 16),
                        _buildResidentSettings(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ── 月份导航 ───────────────────────────────────────────────────

  Widget _buildMonthHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_left, color: AppColors.darkText, size: 24),
                ),
              ),
              const SizedBox(width: 8),
              Text('$_year年$_month月',
                  style: const TextStyle(
                      color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _nextMonth,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_right, color: AppColors.darkText, size: 24),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _goToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('今天',
                  style: TextStyle(
                      color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 星期行 ─────────────────────────────────────────────────────

  Widget _buildWeekdayRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _kWeekdayNames.map((name) {
          return Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(name,
                    style: const TextStyle(color: AppColors.subtitle, fontSize: 12)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 月历网格 ───────────────────────────────────────────────────

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_year, _month, 1);
    final startWeekday = firstDay.weekday; // 1=Mon..7=Sun
    final startOffset = startWeekday - 1;
    final daysInMonth = DateUtils.getDaysInMonth(_year, _month);
    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    final todayStr = _isoDate(DateTime.now());

    // Previous month info for filler cells
    final prevYear = _month == 1 ? _year - 1 : _year;
    final prevMonth = _month == 1 ? 12 : _month - 1;
    final daysInPrevMonth = DateUtils.getDaysInMonth(prevYear, prevMonth);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: List.generate((totalCells / 7).ceil(), (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;

              int day;
              String dateStr;
              bool isCurrentMonth;

              if (cellIndex < startOffset) {
                // Previous month
                day = daysInPrevMonth - startOffset + cellIndex + 1;
                dateStr = _isoDate(DateTime(prevYear, prevMonth, day));
                isCurrentMonth = false;
              } else if (cellIndex < startOffset + daysInMonth) {
                // Current month
                day = cellIndex - startOffset + 1;
                dateStr = _isoDate(DateTime(_year, _month, day));
                isCurrentMonth = true;
              } else {
                // Next month
                day = cellIndex - startOffset - daysInMonth + 1;
                final nextYear = _month == 12 ? _year + 1 : _year;
                final nextMonth = _month == 12 ? 1 : _month + 1;
                dateStr = _isoDate(DateTime(nextYear, nextMonth, day));
                isCurrentMonth = false;
              }

              return Expanded(
                child: _buildDayCell(
                    day, dateStr, isCurrentMonth, dateStr == todayStr),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildDayCell(int day, String dateStr, bool isCurrentMonth, bool isToday) {
    final isSelected = _selectedDate == dateStr;
    final slot = _slots[dateStr];
    final status = (slot != null ? slot['status'] : null) as String? ?? 'AVAILABLE';

    final dotColor = isCurrentMonth ? _statusColor(status) : Colors.transparent;
    final textColor = isCurrentMonth
        ? (isToday ? AppColors.primary : AppColors.darkText)
        : AppColors.subtitle.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: isCurrentMonth
          ? () {
              setState(() => _selectedDate = dateStr);
              _showDayActionMenu(dateStr);
            }
          : null,
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isSelected ? AppColors.primary : textColor,
                fontSize: 14,
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  // ── 日期点击操作菜单 ───────────────────────────────────────────

  void _showDayActionMenu(String dateStr) {
    final dt = DateTime.parse(dateStr);
    final weekdayIndex = dt.weekday - 1; // 0=Mon..6=Sun
    final weekdayLabel = _kWeekdayFull[weekdayIndex];
    final isFixedRest = _restWeekdays.contains(weekdayIndex);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Text(dateStr,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText)),
            const SizedBox(height: 16),
            _actionTile(
              icon: Icons.event_busy,
              color: _kRestColor,
              label: '仅设置这一天为休息',
              onTap: () {
                Navigator.pop(ctx);
                _setSingleDayStatus(dateStr, 'REST');
              },
            ),
            _actionTile(
              icon: Icons.repeat,
              color: _kRestColor,
              label: isFixedRest
                  ? '取消每$weekdayLabel固定休息'
                  : '设为每$weekdayLabel固定休息日',
              onTap: () {
                Navigator.pop(ctx);
                _toggleFixedRestWeekday(weekdayIndex);
              },
            ),
            _actionTile(
              icon: Icons.check_circle_outline,
              color: _kAvailableColor,
              label: '设为可接单',
              onTap: () {
                Navigator.pop(ctx);
                _setSingleDayStatus(dateStr, 'AVAILABLE');
              },
            ),
            _actionTile(
              icon: Icons.help_outline,
              color: _kPendingColor,
              label: '设为待确认',
              onTap: () {
                Navigator.pop(ctx);
                _setSingleDayStatus(dateStr, 'PENDING_CONFIRM');
              },
            ),
            _actionTile(
              icon: Icons.block,
              color: _kOccupiedColor,
              label: '设为已占用',
              onTap: () {
                Navigator.pop(ctx);
                _setSingleDayStatus(dateStr, 'OCCUPIED');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.darkText)),
            ),
            Icon(Icons.chevron_right, color: AppColors.subtitle, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _setSingleDayStatus(String dateStr, String status) async {
    // ── 立即更新本日日历 ──
    final updatedSlots = Map<String, dynamic>.from(_slots);
    final existing = updatedSlots[dateStr];
    if (existing != null) {
      final entry = Map<String, dynamic>.from(existing as Map);
      entry['status'] = status;
      updatedSlots[dateStr] = entry;
    } else {
      updatedSlots[dateStr] = {'date': dateStr, 'status': status, 'note': ''};
    }
    setState(() => _slots = updatedSlots);

    // ── 后端持久化 + 静默刷新 ──
    try {
      final service = context.read<AvailabilityService>();
      await service.batchSetAvailability(dates: [dateStr], status: status);
      await _loadData(showLoading: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('设置失败: $e')));
      }
    }
  }

  Future<void> _toggleFixedRestWeekday(int weekday) async {
    final newList = List<int>.from(_restWeekdays);
    if (newList.contains(weekday)) {
      newList.remove(weekday);
    } else {
      newList.add(weekday);
    }

    // ── 立即更新本月日历：把匹配的星期几全部刷新 ──
    final updatedSlots = Map<String, dynamic>.from(_slots);
    final daysInMonth = DateUtils.getDaysInMonth(_year, _month);
    for (int day = 1; day <= daysInMonth; day++) {
      final d = DateTime(_year, _month, day);
      if (d.weekday - 1 == weekday) {
        final ds = _isoDate(d);
        final existing = updatedSlots[ds];
        if (existing != null) {
          final entry = Map<String, dynamic>.from(existing as Map);
          // 仅修改 AVAILABLE↔REST，不覆盖 OCCUPIED / PENDING_CONFIRM
          if (newList.contains(weekday) && entry['status'] == 'AVAILABLE') {
            entry['status'] = 'REST';
            entry['note'] = '固定休息日';
          } else if (!newList.contains(weekday) && entry['status'] == 'REST') {
            entry['status'] = 'AVAILABLE';
            entry['note'] = '';
          }
          updatedSlots[ds] = entry;
        }
      }
    }

    setState(() {
      _restWeekdays = newList;
      _slots = updatedSlots;
    });

    // ── 后端持久化 + 静默刷新 ──
    try {
      final service = context.read<AvailabilityService>();
      await service.saveRestWeekdays(newList);
      await _loadData(showLoading: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  // ── 选中日期信息 ───────────────────────────────────────────────

  Widget _buildSelectedDayInfo() {
    final slot = _slots[_selectedDate];
    final status = (slot != null ? slot['status'] : null) as String? ?? 'AVAILABLE';
    final note = (slot != null ? slot['note'] : null) as String? ?? '';
    final clr = _statusColor(status);
    final label = _statusLabel(status);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: clr.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: clr.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: clr, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('$_selectedDate',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkText)),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: clr)),
          if (note.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(note,
                  style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
  }

  // ── 状态图例 ───────────────────────────────────────────────────

  Widget _buildLegend() {
    const items = [
      ('AVAILABLE', '可接单'),
      ('OCCUPIED', '已占用'),
      ('PENDING_CONFIRM', '待确认'),
      ('REST', '休息'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _statusColor(item.$1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(item.$2,
                  style: const TextStyle(color: AppColors.subtitle, fontSize: 12)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── 近期安排 ───────────────────────────────────────────────────

  Widget _buildRecentSchedule() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('近期安排',
              style: TextStyle(
                  color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (_recentOrders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: const Center(
                child: Text('暂无近期安排',
                    style: TextStyle(color: AppColors.subtitle, fontSize: 14)),
              ),
            )
          else
            ..._recentOrders.map(_buildOrderCard),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final expoName = order['expoName'] as String? ?? '';
    final dateStart = order['dateStart'] as String? ?? '';
    final dateEnd = order['dateEnd'] as String? ?? '';
    final venue = order['venue'] as String? ?? '';
    final orderStatus = order['orderStatus'] as String? ?? '';

    final statusLabel = _orderStatusLabel(orderStatus);
    final statusClr = _orderStatusColor(orderStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
                color: statusClr, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(expoName,
                          style: const TextStyle(
                              color: AppColors.darkText,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusClr.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: statusClr,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.subtitle),
                  const SizedBox(width: 4),
                  Text('$dateStart ~ $dateEnd',
                      style:
                          const TextStyle(color: AppColors.subtitle, fontSize: 13)),
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
    );
  }

  // ── 常驻设置 ───────────────────────────────────────────────────

  Widget _buildResidentSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('常驻设置',
              style: TextStyle(
                  color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingRow(
                  Icons.location_city_outlined,
                  '服务城市',
                  _serviceCities.isEmpty ? '未设置' : _serviceCities.join('、'),
                ),
                const Divider(height: 24),
                _buildSettingRow(
                  Icons.business_outlined,
                  '常驻展馆',
                  _serviceVenues.isEmpty ? '未设置' : _serviceVenues.join('、'),
                ),
                const Divider(height: 24),
                _buildSettingRow(
                  Icons.event_busy_outlined,
                  '固定休息日',
                  _restWeekdays.isEmpty
                      ? '未设置（点击日历设置）'
                      : _restWeekdays.map((i) => _kWeekdayFull[i]).join('、'),
                ),
                const SizedBox(height: 4),
                const Text(
                  '提示：点击日历中的日期可设置固定休息日',
                  style: TextStyle(fontSize: 11, color: AppColors.subtitle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText)),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(value,
              style: const TextStyle(fontSize: 13, color: AppColors.subtitle)),
        ),
      ],
    );
  }

  // ── 批量设置 ───────────────────────────────────────────────────

  void _openBatchSet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BatchSetSheet(
        initialYear: _year,
        initialMonth: _month,
        onSaved: () => _loadData(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 批量设置底部表单
// ══════════════════════════════════════════════════════════════════

class _BatchSetSheet extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final VoidCallback onSaved;

  const _BatchSetSheet({
    required this.initialYear,
    required this.initialMonth,
    required this.onSaved,
  });

  @override
  State<_BatchSetSheet> createState() => _BatchSetSheetState();
}

class _BatchSetSheetState extends State<_BatchSetSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedStatus = 'AVAILABLE';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(widget.initialYear, widget.initialMonth, 1);
    _endDate = _startDate;
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(picked)) {
            _startDate = picked;
          }
        }
      });
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '请选择';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  List<String> _generateDates() {
    if (_startDate == null || _endDate == null) return [];
    final dates = <String>[];
    var d = _startDate!;
    while (!d.isAfter(_endDate!)) {
      dates.add(_fmtDate(d));
      d = d.add(const Duration(days: 1));
    }
    return dates;
  }

  Future<void> _save() async {
    final dates = _generateDates();
    if (dates.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请选择日期范围')));
      return;
    }

    setState(() => _saving = true);
    try {
      final service = context.read<AvailabilityService>();
      await service.batchSetAvailability(dates: dates, status: _selectedStatus);
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已更新 ${dates.length} 天档期')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('批量设置档期',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText)),
          const SizedBox(height: 20),

          // Date range
          const Text('日期范围',
              style: TextStyle(fontSize: 13, color: AppColors.subtitle)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDateButton('开始', _startDate, true)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('至', style: TextStyle(color: AppColors.subtitle)),
              ),
              Expanded(child: _buildDateButton('结束', _endDate, false)),
            ],
          ),
          const SizedBox(height: 16),

          // Status selector
          const Text('设置状态',
              style: TextStyle(fontSize: 13, color: AppColors.subtitle)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ('AVAILABLE', '可接单'),
              ('OCCUPIED', '已占用'),
              ('PENDING_CONFIRM', '待确认'),
              ('REST', '休息'),
            ].map((item) {
              final selected = _selectedStatus == item.$1;
              final clr = _statusColor(item.$1);
              return GestureDetector(
                onTap: () => setState(() => _selectedStatus = item.$1),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? clr.withValues(alpha: 0.15) : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? clr : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration:
                              BoxDecoration(color: clr, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(item.$2,
                          style: TextStyle(
                            fontSize: 14,
                            color: selected ? clr : AppColors.darkText,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('保存',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String hint, DateTime? value, bool isStart) {
    return GestureDetector(
      onTap: () => _pickDate(isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.subtitle),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value != null ? _fmtDate(value) : hint,
                style: TextStyle(
                  fontSize: 14,
                  color: value != null ? AppColors.darkText : AppColors.subtitle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
