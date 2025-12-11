import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:daoapp/presentation/screens/my_page/my_log/my_log_write_screen.dart';
import 'package:daoapp/presentation/providers/my_log_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/presentation/screens/my_page/my_log/my_log_detail_screen.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class MyLogHomeScreen extends ConsumerWidget {
  const MyLogHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myLogsAsync = ref.watch(myLogProvider);

    return Scaffold(
      appBar: CommonAppBar(
        title: '마이로그',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyLogWriteScreen(
                    initialDate: DateTime.now(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: myLogsAsync.when(
        data: (logs) {
          // 🔹 날짜만 뽑아서 세트로 (달력 마커용)
          final loggedDates = logs.map((log) {
            final d = log.date;
            return DateTime(d.year, d.month, d.day);
          }).toSet();

          // 🔹 정렬된 리스트 (최근순)
          final sortedLogs = [...logs]
            ..sort((a, b) => b.date.compareTo(a.date));

          final totalCount = logs.length;
          final firstLog = sortedLogs.isNotEmpty ? sortedLogs.last : null;
          final latestLog = sortedLogs.isNotEmpty ? sortedLogs.first : null;
          final streakDays = _calculateCurrentStreak(loggedDates);

          return Container(
            color: Colors.grey[100],
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // ==========================
                // 🔥 상단 요약 카드
                // ==========================
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // 왼쪽: 다트 아이콘 영역
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0F172A),
                                Color(0xFF1E293B),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            '🎯',
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 오른쪽: 텍스트 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '나의 다트 이야기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '총 $totalCount개의 기록이 쌓였어요.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // ✅ Row → Wrap 으로 변경 (오버플로우 방지)
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _statChip(
                                    label: '연속 기록',
                                    value: streakDays > 0
                                        ? '$streakDays일'
                                        : '아직 시작 전',
                                    color: Colors.cyan,
                                  ),
                                  if (firstLog != null)
                                    _statChip(
                                      label: '첫 기록',
                                      value: _formatDate(firstLog.date),
                                      color: Colors.orange,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (latestLog != null)
                                Text(
                                  '최근 기록: ${_formatDate(latestLog.date)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================
                // 🎯 달력 카드 (다트 느낌)
                // ==========================
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF020617),
                        Color(0xFF0B1120),
                        Color(0xFF020617),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2024, 1, 1),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: DateTime.now(),
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {
                        CalendarFormat.month: '월',
                      },
                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: Colors.white70,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: Colors.white70,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: Colors.blueGrey[100],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        weekendStyle: const TextStyle(
                          color: Color(0xFFF97373),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        weekendTextStyle: const TextStyle(
                          color: Color(0xFFFECACA),
                          fontSize: 13,
                        ),
                        outsideDaysVisible: false,
                        todayDecoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.cyanAccent,
                            width: 1.5,
                          ),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF22D3EE),
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          final normalized =
                          DateTime(date.year, date.month, date.day);
                          if (loggedDates.contains(normalized)) {
                            return Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(0.7),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                      onDaySelected: (selectedDay, focusedDay) async {
                        final selected = DateTime(
                          selectedDay.year,
                          selectedDay.month,
                          selectedDay.day,
                        );

                        // 해당 날짜에 이미 기록이 있는지 찾기
                        final log = logs
                            .cast<MyLogModel?>()
                            .firstWhere(
                              (l) =>
                          l != null &&
                              DateTime(
                                l.date.year,
                                l.date.month,
                                l.date.day,
                              ) ==
                                  selected,
                          orElse: () => null,
                        );

                        if (log != null && log.id != null) {
                          // ✅ 이미 기록이 있으면 상세 페이지로
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MyLogDetailScreen(logId: log.id!),
                            ),
                          );
                        } else {
                          // ✅ 기록이 없으면: 이 날짜로 새로 작성할지 물어보기
                          if (!context.mounted) return;
                          final confirm = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true, // 🔹 높이 조금 더 여유
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (ctx) {
                              return SafeArea(
                                // 시스템 하단 바에 안 겹치게
                                top: false,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min, // 내용만큼만 높이
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${selected.year}년 ${selected.month}월 ${selected.day}일',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '이 날짜에 새로운 다트 일기를 작성할까요?',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '예시)\n'
                                            '- 오늘 어떤 경기를 했는지\n'
                                            '- 기억에 남는 레그나 샷은?\n'
                                            '- 내일 더 집중하고 싶은 연습은?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          height: 1.5,
                                        ),
                                      ),

                                      // 👇 여기 간격만 주고 버튼, Spacer는 제거!
                                      const SizedBox(height: 24),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('취소'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('작성하기'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );

                          if (confirm == true && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyLogWriteScreen(
                                  initialDate: selected,
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================
                // 안내 텍스트 (버튼은 제거)
                // ==========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '📌 날짜를 탭해서 다트 일기를 작성하거나,\n이미 남긴 기록을 다시 볼 수 있어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ==========================
                // 최근 작성한 일기 3개
                // ==========================
                if (sortedLogs.isNotEmpty) ...[
                  const Text(
                    '최근 작성한 다트 일기',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...sortedLogs.take(3).map(
                        (log) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        onTap: () {
                          if (log.id == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MyLogDetailScreen(logId: log.id!),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange.withOpacity(0.12),
                                ),
                                child: const Icon(
                                  Icons.menu_book_outlined,
                                  color: Colors.orange,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatFullDate(log.date),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '이 날의 다트 이야기를 다시 확인해보세요.',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('오류가 발생했습니다')),
      ),
    );
  }

  // ==========================
  // 헬퍼들
  // ==========================

  /// 현재 연속 기록 일수 계산 (최근 날짜 기준으로 역순 연속 일수)
  int _calculateCurrentStreak(Set<DateTime> loggedDates) {
    if (loggedDates.isEmpty) return 0;

    final uniqueDates = loggedDates.toList()
      ..sort((a, b) => b.compareTo(a)); // 최신 → 과거

    int streak = 1;
    for (int i = 0; i < uniqueDates.length - 1; i++) {
      final current = uniqueDates[i];
      final next = uniqueDates[i + 1];
      final diff = current.difference(next).inDays;

      if (diff == 1) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _formatFullDate(DateTime date) {
    const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayLabel = weekDays[date.weekday - 1];
    return '${date.year}년 ${date.month}월 ${date.day}일 ($weekdayLabel)';
  }

  Widget _statChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: color.darken(),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// 간단한 Color 확장: 살짝 어둡게
extension _ColorX on Color {
  Color darken([double amount = .15]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark =
    hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
