// lib/presentation/screens/user/point_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/data/repositories/point_record_repository.dart';
import 'package:daoapp/data/models/point_record_model.dart';

class PointCalendarScreen extends StatefulWidget {
  const PointCalendarScreen({super.key});

  @override
  State<PointCalendarScreen> createState() => _PointCalendarScreenState();
}

class _PointCalendarScreenState extends State<PointCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<PointRecord>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllPointEvents();
  }

  Future<void> _loadAllPointEvents() async {
    final repo = sl<PointRecordRepository>();

    repo.getAllPointRecords().listen((records) {
      final Map<DateTime, List<PointRecord>> events = {};
      for (var record in records) {
        final date = DateTime(record.date.year, record.date.month, record.date.day);
        events.putIfAbsent(date, () => []).add(record);
      }
      setState(() => _events = events);
    });
  }

  List<PointRecord> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('포인트 달력'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 달력
          AppCard(
            margin: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: AppDateUtils.firstDay,
              lastDay: AppDateUtils.lastDay,
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              eventLoader: _getEventsForDay,
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                // 포인트 수치 제거 → 녹색 점만!
                markerBuilder: (context, day, events) {
                  return events.isNotEmpty
                      ? const Positioned(
                    right: 1,
                    bottom: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 8, height: 8),
                    ),
                  )
                      : null;
                },
              ),
            ),
          ),

          // 선택된 날짜 포인트 내역
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('날짜를 선택하세요'))
                : _getEventsForDay(_selectedDay!).isEmpty
                ? const Center(child: Text('해당 날짜에 포인트 내역 없음'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _getEventsForDay(_selectedDay!).length,
              itemBuilder: (_, i) {
                final record = _getEventsForDay(_selectedDay!)[i];
                return AppCard(
                  child: ListTile(
                    title: Text('${record.koreanName} (${record.englishName})'),
                    subtitle: Text(record.shopName),
                    trailing: Text(
                      '+${record.points}pt',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}