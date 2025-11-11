// lib/presentation/screens/admin/event_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<QueryDocumentSnapshot>> _events = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
    _loadAllEvents();
  }

  void _loadAllEvents() {
    FirebaseFirestore.instance
        .collection('events')
        .orderBy('eventDateTime', descending: true)
        .snapshots()
        .listen((snapshot) {
      final Map<DateTime, List<QueryDocumentSnapshot>> events = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final timestamp = data?['eventDateTime'] as Timestamp?;
        if (timestamp == null) continue;

        final eventDateTime = timestamp.toDate();
        final key = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);
        events.putIfAbsent(key, () => []).add(doc);
      }
      if (mounted) {
        setState(() => _events = events);
      }
    });
  }

  List<QueryDocumentSnapshot> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  String _getEventStatus(DateTime eventDateTime) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    if (eventDateTime.isBefore(todayStart)) {
      return 'completed';
    } else if (isSameDay(eventDateTime, now)) {
      return eventDateTime.isBefore(now) ? 'completed' : 'ongoing';
    } else {
      return 'upcoming';
    }
  }

  // 마이그레이션 함수
  Future<void> _migrateData() async {
    final snapshot = await FirebaseFirestore.instance.collection('events').get();
    int count = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final eventDateTimeField = data['eventDateTime'];

      if (eventDateTimeField is String) {
        final match = RegExp(r'(\d{4})년 (\d{1,2})월 (\d{1,2})일 오([전후]) (\d{1,2})시 (\d{1,2})분').firstMatch(eventDateTimeField);
        if (match != null) {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);
          final isPM = match.group(4) == '후';
          var hour = int.parse(match.group(5)!);
          final minute = int.parse(match.group(6)!);
          if (isPM && hour != 12) hour += 12;
          if (!isPM && hour == 12) hour = 0;
          final eventDateTime = DateTime(year, month, day, hour, minute);

          await doc.reference.update({
            'eventDateTime': Timestamp.fromDate(eventDateTime),
          });
          count++;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count개 데이터 복구 완료!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: '경기 관리',
        showBackButton: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 달력
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppCard(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 400,
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
                        onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                        eventLoader: (day) => _getEventsForDay(day),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          formatButtonShowsNext: false,
                        ),
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          todayDecoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                          todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          selectedDecoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
                          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            if (events.isEmpty) return null;
                            final eventList = events.cast<QueryDocumentSnapshot>();
                            final earliest = eventList.reduce((a, b) {
                              final dataA = a.data() as Map<String, dynamic>?;
                              final dataB = b.data() as Map<String, dynamic>?;
                              final timeA = (dataA?['eventDateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
                              final timeB = (dataB?['eventDateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
                              return timeA.isBefore(timeB) ? a : b;
                            });
                            final data = earliest.data() as Map<String, dynamic>?;
                            final eventDateTime = (data?['eventDateTime'] as Timestamp?)?.toDate();
                            if (eventDateTime == null) return null;
                            final status = _getEventStatus(eventDateTime);
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  color: status == 'completed'
                                      ? Colors.red
                                      : status == 'ongoing'
                                      ? Colors.blue
                                      : Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                          todayBuilder: (context, day, focusedDay) {
                            if (isSameDay(day, _selectedDay)) return null;
                            return Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                                child: Center(
                                  child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            );
                          },
                          selectedBuilder: (context, day, focusedDay) {
                            return Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
                                child: Center(
                                  child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 선택된 날짜 경기 리스트
            if (_selectedDay == null)
              const SliverFillRemaining(child: Center(child: Text('날짜를 선택하세요')))
            else if (_getEventsForDay(_selectedDay!).isEmpty)
              const SliverFillRemaining(child: Center(child: Text('해당 날짜에 경기 없음')))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) {
                      final doc = _getEventsForDay(_selectedDay!)[i];
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data == null) return const SizedBox.shrink();

                      final docId = doc.id;
                      final eventDateTime = (data['eventDateTime'] as Timestamp?)?.toDate();
                      if (eventDateTime == null) return const SizedBox.shrink();

                      final status = _getEventStatus(eventDateTime);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          color: status == 'completed'
                              ? Colors.red.shade50
                              : status == 'ongoing'
                              ? Colors.blue.shade50
                              : Colors.green.shade50,
                          elevation: status == 'completed' ? 6 : 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: status == 'completed'
                                ? BorderSide(color: Colors.red.shade300, width: 1.5)
                                : BorderSide.none,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      RouteConstants.eventEdit,
                                      arguments: {
                                        'docId': docId,
                                        'initialData': data,
                                      },
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: status == 'completed'
                                                ? Colors.red
                                                : status == 'ongoing'
                                                ? Colors.blue
                                                : Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            status == 'completed'
                                                ? Icons.emoji_events
                                                : status == 'ongoing'
                                                ? Icons.schedule
                                                : Icons.event,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['shopName'] ?? '장소 미정',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: status == 'completed' ? FontWeight.bold : FontWeight.w600,
                                                  color: status == 'completed' ? Colors.red.shade900 : null,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${eventDateTime.year}-${eventDateTime.month.toString().padLeft(2, '0')}-${eventDateTime.day.toString().padLeft(2, '0')} ${eventDateTime.hour.toString().padLeft(2, '0')}:${eventDateTime.minute.toString().padLeft(2, '0')}',
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
                                                      '참가비: ${data['entryFee'] ?? 0}원',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: status == 'completed' ? Colors.red.shade700 : Colors.grey.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                  if (status == 'completed' && data['resultImageUrl'] != null) ...[
                                                    const SizedBox(width: 12),
                                                    Icon(Icons.photo, size: 14, color: Colors.amber),
                                                    const SizedBox(width: 4),
                                                    const Text('사진 있음', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteEvent(context, docId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _getEventsForDay(_selectedDay!).length,
                  ),
                ),
              ),
          ],
        ),
      ),
      // 마이그레이션 버튼 추가
      floatingActionButton: FloatingActionButton(
        onPressed: _migrateData,
        child: const Icon(Icons.sync),
        tooltip: '기존 데이터 복구 (eventDateTime → Timestamp)',
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteEvent(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('경기 삭제'),
        content: const Text('정말 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('events').doc(docId).delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('경기가 삭제되었습니다.'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('삭제 실패: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}