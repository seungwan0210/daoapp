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
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      final Map<DateTime, List<QueryDocumentSnapshot>> events = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final timestamp = data['date'] as Timestamp?;
        if (timestamp == null) continue;

        final date = timestamp.toDate();
        final key = DateTime(date.year, date.month, date.day);
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

  String _getEventStatus(DateTime eventDate, String? time) {
    if (time == null || time.isEmpty) return 'upcoming';
    final parts = time.split(':');
    if (parts.length < 2) return 'upcoming';
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final eventDateTime = DateTime(eventDate.year, eventDate.month, eventDate.day, hour, minute);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    if (eventDateTime.isBefore(todayStart)) {
      return 'completed';
    } else if (eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day) {
      return eventDateTime.isBefore(now) ? 'completed' : 'ongoing';
    } else {
      return 'upcoming';
    }
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
            // 달력 (400px 고정 + 오버플로우 방지)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppCard(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 400, // 정확히 400px
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
                              final timeA = (dataA?['time'] as String?) ?? '23:59';
                              final timeB = (dataB?['time'] as String?) ?? '23:59';
                              return timeA.compareTo(timeB) <= 0 ? a : b;
                            });
                            final data = earliest.data() as Map<String, dynamic>?;
                            final time = data?['time'] as String?;
                            final status = _getEventStatus(day, time);
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
                      final timestamp = data['date'] as Timestamp?;
                      if (timestamp == null) return const SizedBox.shrink();

                      final date = timestamp.toDate();
                      final time = data['time'] as String?;
                      final status = _getEventStatus(date, time);

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
                              // 왼쪽: 전체 클릭 → 수정
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      RouteConstants.eventEdit, // 수정 화면
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
                                        // 상태 아이콘
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

                                        // 정보
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
                                                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${time ?? '미정'}',
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

                              // 오른쪽: 삭제 아이콘만
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