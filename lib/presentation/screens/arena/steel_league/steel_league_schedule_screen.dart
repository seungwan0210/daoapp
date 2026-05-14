// lib/presentation/screens/arena/steel_league/steel_league_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가
import 'package:intl/intl.dart'; // 🔹 이 라인을 추가하세요

final calendarProvider =
StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
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
      : super(
    CalendarState(
      format: CalendarFormat.month,
      focusedDay: AppDateUtils.today,
      selectedDay: AppDateUtils.today,
      events: {},
    ),
  ) {
    _loadEvents();
  }

  void _loadEvents() {
    FirebaseFirestore.instance
        .collection('events')
        .snapshots()
        .listen((snapshot) {
      final Map<DateTime, List<Map<String, dynamic>>> events = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['eventDateTime'] as Timestamp?;
        if (timestamp == null) continue;

        final eventDateTime = timestamp.toDate();
        final key = DateTime(
            eventDateTime.year, eventDateTime.month, eventDateTime.day);

        events.putIfAbsent(key, () => []).add({
          ...data,
          'id': doc.id,
          'eventDateTime': eventDateTime,
        });
      }
      state = state.copyWith(events: events);
    });
  }

  void updateFormat(CalendarFormat format) {
    state = state.copyWith(format: format);
  }

  void updateSelectedDay(DateTime selectedDay, DateTime focusedDay) {
    state =
        state.copyWith(selectedDay: selectedDay, focusedDay: focusedDay);
  }

  void updateFocusedDay(DateTime focusedDay) {
    state = state.copyWith(focusedDay: focusedDay);
  }

  List<Map<String, dynamic>> getEventsForDay(DateTime day) {
    return state.events[DateTime(day.year, day.month, day.day)] ?? [];
  }
}

class SteelLeagueScheduleScreen extends StatelessWidget {
  const SteelLeagueScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SteelLeagueScheduleScreenBody();
  }
}

class SteelLeagueScheduleScreenBody extends ConsumerWidget {
  const SteelLeagueScheduleScreenBody({super.key});

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
    final s = AppLocalizations.of(context)!;
    final calendarState = ref.watch(calendarProvider);
    final calendarNotifier = ref.read(calendarProvider.notifier);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString(); // 🔹 현재 로케일

    return Scaffold(
      appBar: AppBar(
        title: Text(s.league_schedule_title),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppCard(
                margin: EdgeInsets.zero,
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: SizedBox(
                  height: 400,
                  child: TableCalendar(
                    locale: locale, // 🔹 다국어 적용
                    firstDay: AppDateUtils.firstDay,
                    lastDay: AppDateUtils.lastDay,
                    focusedDay: calendarState.focusedDay,
                    calendarFormat: calendarState.format,
                    selectedDayPredicate: (day) =>
                        isSameDay(calendarState.selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      calendarNotifier.updateSelectedDay(
                          selectedDay, focusedDay);
                    },
                    onPageChanged: (focusedDay) =>
                        calendarNotifier.updateFocusedDay(focusedDay),
                    eventLoader: (day) =>
                        calendarNotifier.getEventsForDay(day),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle),
                      todayTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                      selectedDecoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle),
                      selectedTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        final eventList =
                        events.cast<Map<String, dynamic>>();
                        final earliest = eventList.reduce((a, b) {
                          final timeA = a['eventDateTime'] as DateTime;
                          final timeB = b['eventDateTime'] as DateTime;
                          return timeA.isBefore(timeB) ? a : b;
                        });
                        final eventDateTime =
                        earliest['eventDateTime'] as DateTime;
                        final status = _getEventStatus(eventDateTime);
                        return Container(
                          width: 6,
                          height: 6,
                          margin:
                          const EdgeInsets.symmetric(horizontal: 1.5),
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
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: calendarState.selectedDay == null
                    ? Center(child: Text(s.league_schedule_empty_day, style: const TextStyle(fontSize: 16)))
                    : calendarNotifier.getEventsForDay(calendarState.selectedDay!).isEmpty
                    ? Center(child: Text(s.league_schedule_no_events, style: const TextStyle(fontSize: 16)))
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
                        color: status == 'completed' ? Colors.red.shade50 : status == 'ongoing' ? Colors.blue.shade50 : Colors.green.shade50,
                        elevation: status == 'completed' ? 6 : 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: status == 'completed' ? BorderSide(color: Colors.red.shade300, width: 1.5) : BorderSide.none,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showEventDetail(context, event, eventDateTime, s),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 52, height: 52,
                                    color: Colors.grey[200],
                                    child: hasImage
                                        ? Image.network(event['resultImageUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildStatusIcon(status))
                                        : _buildStatusIcon(status),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.grey[700]),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${event['shopName'] ?? s.common_select} • ${DateFormat('HH:mm').format(eventDateTime)}',
                                              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.paid, size: 14, color: Colors.green[700]),
                                          const SizedBox(width: 4),
                                          Text('${_formatFee(event['entryFee'])}${s.common_currency_won}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                        ],
                                      ),
                                      if (status == 'completed' && hasWinner)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.emoji_events, size: 14, color: Colors.amber[700]),
                                              const SizedBox(width: 4),
                                              Text(s.league_schedule_winner(winner), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87)),
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

  String _formatFee(dynamic fee) {
    if (fee == null) return '0';
    return NumberFormat('#,###').format(fee is int ? fee : int.tryParse(fee.toString()) ?? 0);
  }

  Widget _buildStatusIcon(String status) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: status == 'completed' ? Colors.red : status == 'ongoing' ? Colors.blue : Colors.green,
        shape: BoxShape.circle,
      ),
      child: Icon(
        status == 'completed' ? Icons.emoji_events : status == 'ongoing' ? Icons.schedule : Icons.event,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  void _showEventDetail(BuildContext context, Map<String, dynamic> event, DateTime eventDateTime, AppLocalizations s) {
    final status = _getEventStatus(eventDateTime);
    final hasImage = event['resultImageUrl'] != null;
    final winner = event['winner'] as String?;
    final hasWinner = winner != null && winner.trim().isNotEmpty;
    final String shopName = event['shopName'] ?? s.common_select;

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
              if (hasImage)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(event['resultImageUrl'], height: 260, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 260, color: Colors.grey[200], child: const Center(child: Icon(Icons.error, size: 40, color: Colors.red)))),
                )
              else
                Container(
                  height: 180,
                  decoration: const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.white70), const SizedBox(height: 8), Text(s.league_schedule_no_photo, style: const TextStyle(color: Colors.white70, fontSize: 15))])),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.league_schedule_match_suffix(shopName), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildCompactRow(s.league_schedule_detail_date, DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toString()).format(eventDateTime)),
                      _buildCompactRow(s.league_schedule_detail_time, DateFormat('HH:mm').format(eventDateTime)),
                      _buildCompactRow(s.league_schedule_detail_location, shopName),
                      _buildCompactRow(s.league_schedule_detail_fee, '${_formatFee(event['entryFee'])}${s.common_currency_won}'),
                      const SizedBox(height: 12),
                      _buildCompactRow(s.league_schedule_detail_admin, event['admin'] ?? s.common_select),
                      _buildCompactRow(s.league_schedule_detail_contact, event['contact'] ?? s.common_select),
                      const SizedBox(height: 12),
                      if (status == 'completed') ...[
                        _buildCompactRow(s.league_schedule_detail_status, s.league_schedule_status_completed, color: Colors.red),
                        if (hasWinner) Padding(padding: const EdgeInsets.only(top: 6), child: _buildCompactRow(s.league_schedule_winner('').split(':')[0], winner, color: Colors.black87, fontWeight: FontWeight.bold)),
                      ] else
                        _buildCompactRow(s.league_schedule_detail_status, status == 'ongoing' ? s.league_schedule_status_ongoing : s.league_schedule_status_upcoming, color: status == 'ongoing' ? Colors.blue : Colors.green),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), backgroundColor: Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text(s.common_cancel.replaceAll('취소', '닫기'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), // '닫기'로 번역 유도
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRow(String label, String value, {Color? color, FontWeight? fontWeight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: fontWeight))),
        ],
      ),
    );
  }
}