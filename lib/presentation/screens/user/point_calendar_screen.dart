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
        final date = DateTime(record.date.year, record.date.month, record.date.day); // ← .day 추가
        events.putIfAbsent(date, () => []).add(record);
      }
      setState(() => _events = events);
    });
  }

  List<PointRecord> _getEventsForDay(DateTime day) {
    final events = _events[DateTime(day.year, day.month, day.day)] ?? [];

    events.sort((a, b) => b.points.compareTo(a.points));

    int currentRank = 1;
    int? previousPoints;

    for (int i = 0; i < events.length; i++) {
      if (i == 0) {
        currentRank = 1;
      } else if (events[i].points == previousPoints!) {
        // 같은 포인트 → 같은 순위 유지
      } else {
        currentRank = i + 1;
      }
      events[i] = events[i].copyWith(rank: currentRank);
      previousPoints = events[i].points;
    }

    return events;
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
                markerBuilder: (context, day, events) {
                  return events.isNotEmpty
                      ? const Align(
                    alignment: Alignment.bottomCenter,
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

          // 선택된 날짜 포인트 내역 (포인트 높은 순 + 순위)
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
                final rank = record.rank ?? i + 1;

                return AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // 순위
                        SizedBox(
                          width: 36,
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: rank == 1 ? Colors.amber : Colors.blue,
                            ),
                          ),
                        ),
                        // 이름
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.koreanName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                record.englishName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        // 샵
                        Expanded(
                          flex: 2,
                          child: Text(
                            record.shopName,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // 포인트
                        Expanded(
                          flex: 1,
                          child: Text(
                            '+${record.points}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
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