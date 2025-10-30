// lib/presentation/screens/user/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
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
        });
      }
      setState(() => _events = events);
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Color _getMarkerColor(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(day.year, day.month, day.day);
    if (!_events.containsKey(eventDay)) return Colors.transparent;
    return eventDay.isBefore(today) ? Colors.red : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('경기 일정')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2026, 1, 1),
            lastDay: DateTime.utc(2027, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _format,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) => setState(() => _format = format),
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final color = _getMarkerColor(day);
                if (color == Colors.transparent) return null;
                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('날짜를 선택하세요'))
                : _getEventsForDay(_selectedDay!).isEmpty
                ? const Center(child: Text('경기 없음'))
                : ListView.builder(
              itemCount: _getEventsForDay(_selectedDay!).length,
              itemBuilder: (_, i) {
                final event = _getEventsForDay(_selectedDay!)[i];
                final isPast = DateTime.now().isAfter((event['date'] as Timestamp).toDate());
                return ListTile(
                  leading: Icon(
                    isPast ? Icons.check_circle : Icons.event,
                    color: isPast ? Colors.red : Colors.green,
                  ),
                  title: Text(event['title'] ?? '경기'),
                  subtitle: Text(
                    '${event['shopName']} • ${event['time']} • 참가비: ${event['entryFee']}원',
                  ),
                  onTap: () => _showEventDetail(context, event),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetail(BuildContext context, Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event['title'] ?? '경기 상세'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('장소: ${event['shopName']}'),
            Text('시간: ${event['time']}'),
            Text('참가비: ${event['entryFee']}원'),
            if (event['status'] == 'completed') ...[
              const Divider(),
              Text('우승자: ${event['winnerName']}'),
              if (event['resultImageUrl'] != null)
                Image.network(
                  event['resultImageUrl'],
                  height: 200,
                  fit: BoxFit.cover,
                ),
            ],
          ],
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
}