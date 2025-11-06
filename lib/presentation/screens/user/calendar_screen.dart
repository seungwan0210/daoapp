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
                onFormatChanged: null, // 터치해도 안 바뀜!
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
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
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
                  return AppCard(
                    color: isCompleted ? Colors.red.shade50 : Colors.green.shade50,
                    elevation: isCompleted ? 6 : 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isCompleted
                          ? BorderSide(color: Colors.red.shade300, width: 1.5)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCompleted ? Colors.red : Colors.green,
                        child: Icon(
                          isCompleted ? Icons.emoji_events : Icons.event,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        event['title'],
                        style: TextStyle(
                          fontWeight: isCompleted ? FontWeight.bold : FontWeight.w600,
                          color: isCompleted ? Colors.red.shade900 : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${event['shopName']} • ${event['time']}'),
                          Text(
                            '참가비: ${event['entryFee']}원',
                            style: TextStyle(
                              color: isCompleted ? Colors.red.shade700 : Colors.grey.shade700,
                            ),
                          ),
                          if (isCompleted && event['winnerName'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '우승자: ${event['winnerName']}',
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: isCompleted
                          ? Icon(Icons.check_circle, color: Colors.red)
                          : Icon(Icons.schedule, color: Colors.green),
                      onTap: () => _showEventDetail(context, event, eventDate),
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

  static void _showEventDetail(BuildContext context, Map<String, dynamic> event, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event['title'], style: Theme.of(context).textTheme.titleLarge),
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