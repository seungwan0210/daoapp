// lib/presentation/screens/user/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';

// Riverpod 상태 관리
final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier();
});

class CalendarState {
  final CalendarFormat format;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, List<Map<String, dynamic>>> events;

  CalendarState({
    required this.format,
    required this.focusedDay,
    this.selectedDay,
    required this.events,
  });

  CalendarState copyWith({
    CalendarFormat? format,
    DateTime? focusedDay,
    DateTime? selectedDay,
    Map<DateTime, List<Map<String, dynamic>>>? events,
  }) {
    return CalendarState(
      format: format ?? this.format,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      events: events ?? this.events,
    );
  }
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier()
      : super(CalendarState(
    format: CalendarFormat.month,
    focusedDay: AppDateUtils.today,
    selectedDay: AppDateUtils.today,
    events: {},
  )) {
    _loadEvents();
  }

  void _loadEvents() {
    FirebaseFirestore.instance.collection('events').snapshots().listen((snapshot) {
      final Map<DateTime, List<Map<String, dynamic>>> events = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['date'] as Timestamp;
        final date = timestamp.toDate();
        final key = DateTime(date.year, date.month, date.day);
        events.putIfAbsent(key, () => []).add({
          ...data,
          'id': doc.id,
          'title': '${data['shopName']} 경기',
        });
      }
      state = state.copyWith(events: events);
    });
  }

  void updateFormat(CalendarFormat format) {
    state = state.copyWith(format: format);
  }

  void updateSelectedDay(DateTime selectedDay, DateTime focusedDay) {
    state = state.copyWith(selectedDay: selectedDay, focusedDay: focusedDay);
  }

  void updateFocusedDay(DateTime focusedDay) {
    state = state.copyWith(focusedDay: focusedDay);
  }

  List<Map<String, dynamic>> getEventsForDay(DateTime day) {
    return state.events[DateTime(day.year, day.month, day.day)] ?? [];
  }
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});
  static Widget body() => const CalendarScreenBody();
  @override
  Widget build(BuildContext context) {
    return CalendarScreen.body();
  }
}

class CalendarScreenBody extends ConsumerWidget {
  const CalendarScreenBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarProvider);
    final calendarNotifier = ref.read(calendarProvider.notifier);
    final theme = Theme.of(context);

    return SafeArea(
      top: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 캘린더
            AppCard(
              margin: EdgeInsets.zero,
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: TableCalendar(
                firstDay: AppDateUtils.firstDay,
                lastDay: AppDateUtils.lastDay,
                focusedDay: calendarState.focusedDay,
                calendarFormat: calendarState.format,
                selectedDayPredicate: (day) => isSameDay(calendarState.selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  calendarNotifier.updateSelectedDay(selectedDay, focusedDay);
                },
                onFormatChanged: null,
                onPageChanged: (focusedDay) => calendarNotifier.updateFocusedDay(focusedDay),
                eventLoader: calendarNotifier.getEventsForDay,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  titleTextStyle: theme.textTheme.titleLarge!,
                  formatButtonTextStyle: theme.textTheme.bodyMedium!,
                  formatButtonDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  // 오늘: 파란색 (기본)
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  // 선택: 주황색 (구분됨)
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    final isPast = day.isBefore(AppDateUtils.today);
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: isPast ? Colors.red : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                  // 오늘 날짜 커스텀 (선택된 경우는 selectedBuilder가 우선)
                  todayBuilder: (context, day, focusedDay) {
                    if (isSameDay(day, calendarState.selectedDay)) return null; // 선택된 경우는 selectedBuilder 사용
                    return Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                  // 선택된 날짜 커스텀 (오늘 포함)
                  selectedBuilder: (context, day, focusedDay) {
                    return Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 선택된 날짜의 경기 목록
            Expanded(
              child: calendarState.selectedDay == null
                  ? Center(
                child: Text(
                  '날짜를 선택하세요',
                  style: theme.textTheme.bodyLarge,
                ),
              )
                  : calendarNotifier.getEventsForDay(calendarState.selectedDay!).isEmpty
                  ? Center(
                child: Text(
                  '경기 없음',
                  style: theme.textTheme.bodyLarge,
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: calendarNotifier.getEventsForDay(calendarState.selectedDay!).length,
                itemBuilder: (_, i) {
                  final event = calendarNotifier.getEventsForDay(calendarState.selectedDay!)[i];
                  final eventDate = (event['date'] as Timestamp).toDate();
                  final isCompleted = event['status'] == 'completed';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      color: isCompleted ? Colors.red.shade50 : Colors.green.shade50,
                      elevation: isCompleted ? 6 : 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isCompleted
                            ? BorderSide(color: Colors.red.shade300, width: 1.5)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showEventDetail(context, event, eventDate),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // 상태 아이콘
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCompleted ? Colors.red : Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCompleted ? Icons.emoji_events : Icons.event,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 정보 영역
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['title'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.w600,
                                        color: isCompleted ? Colors.red.shade900 : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${event['shopName']} • ${event['time']}',
                                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '참가비: ${event['entryFee']}원',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isCompleted ? Colors.red.shade700 : Colors.grey.shade700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isCompleted && event['winnerName'] != null) ...[
                                          const SizedBox(width: 12),
                                          Icon(Icons.star, size: 14, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              '우승: ${event['winnerName']}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red.shade900,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isCompleted ? Icons.check_circle : Icons.schedule,
                                color: isCompleted ? Colors.red : Colors.green,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 다이얼로그
  static void _showEventDetail(BuildContext context, Map<String, dynamic> event, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          event['title'],
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(context, '날짜', AppDateUtils.formatKoreanDate(date)),
              _buildDetailRow(context, '시간', event['time']),
              _buildDetailRow(context, '장소', event['shopName']),
              _buildDetailRow(context, '참가비', '${event['entryFee']}원'),
              if (event['status'] == 'completed') ...[
                const Divider(height: 20),
                _buildDetailRow(context, '상태', '종료됨', color: Colors.red),
                _buildDetailRow(context, '우승자', event['winnerName'] ?? '미정'),
                if (event['resultImageUrl'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        event['resultImageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error, color: Colors.red),
                        ),
                      ),
                    ),
                  ),
              ] else
                _buildDetailRow(context, '상태', '예정', color: Colors.green),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}