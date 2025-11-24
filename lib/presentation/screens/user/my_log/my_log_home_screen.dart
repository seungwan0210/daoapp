import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:daoapp/presentation/screens/user/my_log/my_log_write_screen.dart';
import 'package:daoapp/presentation/providers/my_log_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/presentation/screens/user/my_log/my_log_detail_screen.dart';

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
          // 기록 있는 날짜들 세트로 만들기
          final loggedDates = logs.map((log) {
            final d = log.date;
            return DateTime(d.year, d.month, d.day);
          }).toSet();

          return Container(
            color: Colors.grey[100],
            child: Column(
              children: [
                const SizedBox(height: 12),
                // 🔹 달력 카드만 표시
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  shape: BoxShape.circle,
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
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (ctx) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 20, 20, 32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('취소'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('작성하기'),
                                        ),
                                      ],
                                    ),
                                  ],
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

                const SizedBox(height: 24),

                // 작은 안내 텍스트 하나만
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '📌 날짜를 탭해서 다트 일기를 작성하거나,\n이미 남긴 기록을 다시 볼 수 있어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
        const Center(child: Text('오류가 발생했습니다')),
      ),
    );
  }
}
