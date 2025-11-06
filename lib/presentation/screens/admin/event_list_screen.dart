// lib/presentation/screens/admin/event_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';

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
    _selectedDay = _focusedDay;
    _loadAllEvents();
  }

  Future<void> _loadAllEvents() async {
    FirebaseFirestore.instance
        .collection('events')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      final Map<DateTime, List<QueryDocumentSnapshot>> events = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['date'] as Timestamp).toDate();
        final key = DateTime(date.year, date.month, date.day);
        events.putIfAbsent(key, () => []).add(doc);
      }
      setState(() => _events = events);
    });
  }

  List<QueryDocumentSnapshot> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('경기 관리'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 달력
            SliverToBoxAdapter(
              child: AppCard(
                margin: const EdgeInsets.all(16),
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  onFormatChanged: null,
                  onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                  eventLoader: _getEventsForDay,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: isPast ? Colors.red : Colors.green,
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
            ),

            // 선택된 날짜 경기 리스트
            _selectedDay == null
                ? SliverFillRemaining(
              child: const Center(child: Text('날짜를 선택하세요')),
            )
                : _getEventsForDay(_selectedDay!).isEmpty
                ? SliverFillRemaining(
              child: const Center(child: Text('해당 날짜에 경기 없음')),
            )
                : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) {
                    final doc = _getEventsForDay(_selectedDay!)[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final date = (data['date'] as Timestamp).toDate();
                    final isCompleted = data['status'] == 'completed';

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
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteConstants.eventCreate,
                            arguments: {
                              'editMode': true,
                              'docId': docId,
                              'initialData': data,
                            },
                          ),
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

                                // 정보
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['shopName'],
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
                                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${data['time']}',
                                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '참가비: ${data['entryFee']}원',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isCompleted ? Colors.red.shade700 : Colors.grey.shade700,
                                            ),
                                          ),
                                          if (isCompleted && data['winnerName'] != null) ...[
                                            const SizedBox(width: 12),
                                            Icon(Icons.star, size: 14, color: Colors.amber),
                                            const SizedBox(width: 4),
                                            Text(
                                              '우승: ${data['winnerName']}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red.shade900,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // 삭제 버튼
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteEvent(context, docId),
                                ),
                              ],
                            ),
                          ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('events').doc(docId).delete();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('경기가 삭제되었습니다.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}