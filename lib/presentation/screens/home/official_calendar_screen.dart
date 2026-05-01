import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/core/services/google_calendar_service.dart';

class OfficialCalendarScreen extends StatefulWidget {
  const OfficialCalendarScreen({super.key});

  @override
  State<OfficialCalendarScreen> createState() => _OfficialCalendarScreenState();
}

class _OfficialCalendarScreenState extends State<OfficialCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _cachedGoogleEvents = [];
  bool _isGoogleLoading = true;

  final String adminUid = "NanHPgCdsbMCFkHEs7MtxS51OSX2";

  final List<String> _calendarIds = [
    "f9835d9449eb197aa4a28882d6b6b0921047274d9d4b9bb9b472dcbec53255c4@group.calendar.google.com",
    "ab9da573f02ba69a46207d551d3d1e1fc159757ccd90cee2e3804a676914f91c@group.calendar.google.com",
    "c012aafa1e98360bb080db8b43c8b1bc560d61d8c7ed28c076bc80a181af52cc@group.calendar.google.com",
    "39t7lea718pdr5f51sts0ljo8u98pub6@import.calendar.google.com",
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadThreeMonthsEvents();
  }

  Future<void> _loadThreeMonthsEvents() async {
    try {
      final months = [
        _focusedDay,
        DateTime(_focusedDay.year, _focusedDay.month + 1, 1),
        DateTime(_focusedDay.year, _focusedDay.month + 2, 1)
      ];
      final results = await Future.wait(
          months.map((month) => sl<GoogleCalendarService>().fetchMergedEvents(_calendarIds, month))
      );
      if (mounted) {
        setState(() {
          _cachedGoogleEvents = results.expand((x) => x).toList();
          _isGoogleLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Map<String, dynamic> _getEventConfig(String? calendarId, {String? firestoreType}) {
    if (calendarId != null) {
      if (calendarId.contains("f9835d")) return {'color': Colors.red, 'logo': 'phoenix'};
      if (calendarId.contains("ab9da5")) return {'color': Colors.blue, 'logo': 'dartslive'};
      if (calendarId.contains("c012aafa")) return {'color': Colors.yellow[700], 'logo': 'pdc'};
      if (calendarId.contains("39t7lea")) return {'color': Colors.greenAccent[700], 'logo': 'wdf'};
    }
    switch (firestoreType) {
      case 'domestic': return {'color': Colors.blue, 'logo': 'league'};
      case 'overseas': return {'color': Colors.yellow[700], 'logo': 'pdc'};
      case 'league': return {'color': Colors.greenAccent[700], 'logo': 'league'};
      default: return {'color': Colors.grey, 'logo': 'none'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CommonAppBar(title: '공식 일정 달력', showBackButton: true),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('official_calendar').snapshots(),
          builder: (context, firestoreSnapshot) {
            final fDocs = firestoreSnapshot.data?.docs ?? [];

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2025, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    locale: 'ko_KR',
                    headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),

                    // ✅ [해결] calendarStyle 안으로 이동시켜야 에러가 안 납니다.
                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: false, // 이번 달이 아닌 날짜 숨기기
                    ),

                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
                    },
                    eventLoader: (day) {
                      final targetDate = DateTime(day.year, day.month, day.day);
                      List<dynamic> events = [];
                      events.addAll(fDocs.where((doc) => _isDateInRange(targetDate, doc['startDate'], doc['endDate'])));
                      events.addAll(_cachedGoogleEvents.where((e) {
                        final s = e['start']?['dateTime'] ?? e['start']?['date'];
                        if (s == null) return false;
                        final sDateOriginal = DateTime.parse(s).toLocal();
                        final sDate = DateTime(sDateOriginal.year, sDateOriginal.month, sDateOriginal.day);
                        final ev = e['end']?['dateTime'] ?? e['end']?['date'];
                        if (ev != null) {
                          final eDateOriginal = DateTime.parse(ev).toLocal();
                          var eDate = DateTime(eDateOriginal.year, eDateOriginal.month, eDateOriginal.day);
                          if (e['start']?['date'] != null) { eDate = eDate.subtract(const Duration(days: 1)); }
                          if (sDate.isAtSameMomentAs(eDate)) { return targetDate.isAtSameMomentAs(sDate); }
                          return _isDateInSimpleRange(targetDate, sDate, eDate);
                        }
                        return targetDate.isAtSameMomentAs(sDate);
                      }));
                      return events;
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return const SizedBox.shrink();
                        final colors = events.map((e) {
                          if (e is QueryDocumentSnapshot) return _getEventConfig(null, firestoreType: (e.data() as Map)['type'])['color'];
                          return _getEventConfig((e as Map)['calendarId'])['color'];
                        }).toSet().toList();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: colors.take(4).map((c) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.0),
                              width: 6, height: 6,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: c)
                          )).toList(),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text("${_selectedDay!.month}월 ${_selectedDay!.day}일 일정",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                ),
                Expanded(
                  child: Container(
                      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                      child: _isGoogleLoading && _cachedGoogleEvents.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : _buildIntegratedList(_selectedDay!, fDocs, _cachedGoogleEvents, user)
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntegratedList(DateTime date, List<QueryDocumentSnapshot> fDocs, List<Map<String, dynamic>> gEvents, User? user) {
    final tDate = DateTime(date.year, date.month, date.day);
    final filteredF = fDocs.where((doc) => _isDateInRange(tDate, doc['startDate'], doc['endDate'])).toList();
    final filteredG = gEvents.where((e) {
      final s = e['start']?['dateTime'] ?? e['start']?['date'];
      if (s == null) return false;
      final sDateOriginal = DateTime.parse(s).toLocal();
      final sDate = DateTime(sDateOriginal.year, sDateOriginal.month, sDateOriginal.day);
      final ev = e['end']?['dateTime'] ?? e['end']?['date'];
      if (ev != null) {
        final eDateOriginal = DateTime.parse(ev).toLocal();
        var eDate = DateTime(eDateOriginal.year, eDateOriginal.month, eDateOriginal.day);
        if (e['start']?['date'] != null) { eDate = eDate.subtract(const Duration(days: 1)); }
        if (sDate.isAtSameMomentAs(eDate)) { return tDate.isAtSameMomentAs(sDate); }
        return _isDateInSimpleRange(tDate, sDate, eDate);
      }
      return tDate.isAtSameMomentAs(sDate);
    }).toList();
    final combined = [...filteredF, ...filteredG];
    combined.sort((a, b) {
      final aId = (a is QueryDocumentSnapshot) ? "" : (a as Map)['calendarId'].toString();
      if (aId.contains("c012aafa") || aId.contains("ab9da5")) return -1;
      return 1;
    });
    if (combined.isEmpty) return const Center(child: Text("일정이 없습니다.", style: TextStyle(color: Colors.grey)));
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: combined.map((item) {
        if (item is QueryDocumentSnapshot) {
          final data = item.data() as Map<String, dynamic>;
          return _buildEventRow(title: data['title'], venue: data['venue'], firestoreType: data['type'], onDelete: user?.uid == adminUid ? () => _deleteEvent(item.id) : null);
        } else {
          final e = item as Map<String, dynamic>;
          return _buildEventRow(title: e['summary'] ?? "제목 없음", venue: e['location'], calendarId: e['calendarId'], isGoogle: true);
        }
      }).toList(),
    );
  }

  bool _isDateInSimpleRange(DateTime target, DateTime start, DateTime end) {
    return (target.isAtSameMomentAs(start) || target.isAfter(start)) &&
        (target.isAtSameMomentAs(end) || target.isBefore(end));
  }

  bool _isDateInRange(DateTime target, dynamic start, dynamic end) {
    if (start == null || end == null) return false;
    final sDate = (start as Timestamp).toDate();
    final eDate = (end as Timestamp).toDate();
    return _isDateInSimpleRange(target, DateTime(sDate.year, sDate.month, sDate.day), DateTime(eDate.year, eDate.month, eDate.day));
  }

  Widget _buildEventRow({required String title, String? venue, String? calendarId, String? firestoreType, bool isGoogle = false, VoidCallback? onDelete}) {
    final config = _getEventConfig(calendarId, firestoreType: firestoreType);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildLogoIcon(config['logo']),
          const SizedBox(width: 16),
          Container(width: 4, height: 32, decoration: BoxDecoration(color: config['color'], borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis), if (venue != null) Text(venue, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)])),
          if (onDelete != null) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: onDelete),
        ],
      ),
    );
  }

  Widget _buildLogoIcon(String? logoKey) {
    return Container(
        width: 40, height: 40,
        child: ClipOval(child: logoKey == null || logoKey == 'none'
            ? const Icon(Icons.emoji_events, color: Colors.grey)
            : Image.asset('assets/images/logos/$logoKey.png', fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)))
    );
  }

  Future<void> _deleteEvent(String docId) async {
    final bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text("삭제"),
            content: const Text("정말 삭제하시겠습니까?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red)))
            ]
        )
    );
    if (confirm == true) await FirebaseFirestore.instance.collection('official_calendar').doc(docId).delete();
  }
}