// lib/presentation/screens/user/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

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
        final timestamp = data['eventDateTime'] as Timestamp?;
        if (timestamp == null) continue;

        final eventDateTime = timestamp.toDate();
        final key = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);

        events.putIfAbsent(key, () => []).add({
          ...data,
          'id': doc.id,
          'title': '${data['shopName'] ?? '경기'} 경기',
          'eventDateTime': eventDateTime, // 상태 판단용
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

  @override
  Widget build(BuildContext context) {
    return const CalendarScreenBody();
  }
}

class CalendarScreenBody extends ConsumerWidget {
  const CalendarScreenBody({super.key});

  // eventDateTime 기준으로 상태 판단
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarProvider);
    final calendarNotifier = ref.read(calendarProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 캘린더
              AppCard(
                margin: EdgeInsets.zero,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: SizedBox(
                  height: 400,
                  child: TableCalendar(
                    firstDay: AppDateUtils.firstDay,
                    lastDay: AppDateUtils.lastDay,
                    focusedDay: calendarState.focusedDay,
                    calendarFormat: calendarState.format,
                    selectedDayPredicate: (day) => isSameDay(calendarState.selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      calendarNotifier.updateSelectedDay(selectedDay, focusedDay);
                    },
                    onPageChanged: (focusedDay) => calendarNotifier.updateFocusedDay(focusedDay),
                    eventLoader: (day) => calendarNotifier.getEventsForDay(day),
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
                        final eventList = events.cast<Map<String, dynamic>>();
                        final earliest = eventList.reduce((a, b) {
                          final timeA = a['eventDateTime'] as DateTime;
                          final timeB = b['eventDateTime'] as DateTime;
                          return timeA.isBefore(timeB) ? a : b;
                        });
                        final eventDateTime = earliest['eventDateTime'] as DateTime;
                        final status = _getEventStatus(eventDateTime);
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: status == 'completed'
                                ? Colors.red
                                : status == 'ongoing'
                                ? Colors.blue
                                : Colors.green,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        if (isSameDay(day, calendarState.selectedDay)) return null;
                        return Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                            child: Center(child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                        );
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        return Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
                            child: Center(child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 경기 목록
              Expanded(
                child: calendarState.selectedDay == null
                    ? const Center(child: Text('날짜를 선택하세요', style: TextStyle(fontSize: 16)))
                    : calendarNotifier.getEventsForDay(calendarState.selectedDay!).isEmpty
                    ? const Center(child: Text('경기 없음', style: TextStyle(fontSize: 16)))
                    : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: calendarNotifier.getEventsForDay(calendarState.selectedDay!).length,
                  itemBuilder: (_, i) {
                    final event = calendarNotifier.getEventsForDay(calendarState.selectedDay!)[i];
                    final eventDateTime = event['eventDateTime'] as DateTime;
                    final status = _getEventStatus(eventDateTime);

                    final winner = event['winner'] as String?;
                    final hasWinner = winner != null && winner.trim().isNotEmpty;
                    final hasImage = event['resultImageUrl'] != null;

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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showEventDetail(context, event, eventDateTime),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 왼쪽: 사진 있으면 썸네일, 없으면 o형 아이콘
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    color: Colors.grey[200],
                                    child: hasImage
                                        ? Image.network(
                                      event['resultImageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildStatusIcon(status),
                                    )
                                        : _buildStatusIcon(status),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 오른쪽: 정보
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 장소 + 시간
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.grey[700]),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${event['shopName'] ?? '장소 미정'} • ${eventDateTime.hour.toString().padLeft(2, '0')}:${eventDateTime.minute.toString().padLeft(2, '0')}',
                                              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // 참가비
                                      Row(
                                        children: [
                                          Icon(Icons.paid, size: 14, color: Colors.green[700]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${event['entryFee'] ?? 0}원',
                                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                          ),
                                        ],
                                      ),

                                      // 우승자 (종료된 경기 + 우승자 있음)
                                      if (status == 'completed' && hasWinner)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.emoji_events, size: 14, color: Colors.amber[700]),
                                              const SizedBox(width: 4),
                                              Text(
                                                '우승자: $winner',
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
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
      ),
    );
  }

  // 상태별 o형 아이콘
  Widget _buildStatusIcon(String status) {
    return Container(
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
        size: 20,
      ),
    );
  }

  // === 팝업 다이얼로그: 사진 위 + 글자 컴팩트 (인스타 스타일) ===
  void _showEventDetail(BuildContext context, Map<String, dynamic> event, DateTime eventDateTime) {
    final status = _getEventStatus(eventDateTime);
    final hasImage = event['resultImageUrl'] != null;
    final winner = event['winner'] as String?;
    final hasWinner = winner != null && winner.trim().isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.92,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 사진 (상단)
              if (hasImage)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    event['resultImageUrl'],
                    height: 260,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 260,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.error, size: 40, color: Colors.red)),
                    ),
                  ),
                )
              else
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.white70),
                        SizedBox(height: 8),
                        Text('사진 없음', style: TextStyle(color: Colors.white70, fontSize: 15)),
                      ],
                    ),
                  ),
                ),

              // 정보 (하단)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        event['title'] ?? '경기',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      _buildCompactRow(context, '날짜', AppDateUtils.formatKoreanDate(eventDateTime)),
                      _buildCompactRow(context, '시간', '${eventDateTime.hour.toString().padLeft(2, '0')}:${eventDateTime.minute.toString().padLeft(2, '0')}'),
                      _buildCompactRow(context, '장소', event['shopName'] ?? '미정'),
                      _buildCompactRow(context, '참가비', '${event['entryFee'] ?? 0}원'),
                      const SizedBox(height: 12),

                      _buildCompactRow(context, '관리자', event['admin'] ?? '미정'),
                      _buildCompactRow(context, '연락처', event['contact'] ?? '미정'),
                      const SizedBox(height: 12),

                      if (status == 'completed') ...[
                        _buildCompactRow(context, '상태', '종료됨', color: Colors.red),
                        if (hasWinner)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: _buildCompactRow(
                              context,
                              '우승자',
                              winner,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ] else
                        _buildCompactRow(
                          context,
                          '상태',
                          status == 'ongoing' ? '진행' : '예정',
                          color: status == 'ongoing' ? Colors.blue : Colors.green,
                        ),
                    ],
                  ),
                ),
              ),

              // 닫기 버튼
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('닫기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRow(BuildContext context, String label, String value, {Color? color, FontWeight? fontWeight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: fontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}