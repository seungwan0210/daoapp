// lib/presentation/screens/user/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  static Widget body() => const CalendarScreen();

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _format = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = AppDateUtils.today;
    _selectedDay = _focusedDay;
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
      if (mounted) {
        setState(() => _events = events);
      }
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return CalendarScreenBody(state: this);
  }
}

class CalendarScreenBody extends StatelessWidget {
  final _CalendarScreenState state;

  const CalendarScreenBody({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 캘린더
        AppCard(
          margin: const EdgeInsets.all(16),
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: TableCalendar(
            firstDay: AppDateUtils.firstDay,
            lastDay: AppDateUtils.lastDay,
            focusedDay: state._focusedDay,
            calendarFormat: state._format,
            selectedDayPredicate: (day) => isSameDay(state._selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              state.setState(() {
                state._selectedDay = selectedDay;
                state._focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) => state.setState(() => state._format = format),
            onPageChanged: (focusedDay) => state._focusedDay = focusedDay,
            eventLoader: state._getEventsForDay,
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
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

        // 선택된 날짜의 경기 목록
        Expanded(
          child: state._selectedDay == null
              ? Center(
            child: Text(
              '날짜를 선택하세요',
              style: theme.textTheme.bodyLarge,
            ),
          )
              : state._getEventsForDay(state._selectedDay!).isEmpty
              ? Center(
            child: Text(
              '경기 없음',
              style: theme.textTheme.bodyLarge,
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state._getEventsForDay(state._selectedDay!).length,
            itemBuilder: (_, i) {
              final event = state._getEventsForDay(state._selectedDay!)[i];
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