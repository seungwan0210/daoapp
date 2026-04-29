import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class OfficialCalendarScreen extends StatefulWidget {
  const OfficialCalendarScreen({super.key});

  @override
  State<OfficialCalendarScreen> createState() => _OfficialCalendarScreenState();
}

class _OfficialCalendarScreenState extends State<OfficialCalendarScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final String adminUid = "NanHPgCdsbMCFkHEs7MtxS51OSX2";

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Future<void> _deleteEvent(String docId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("일정 삭제"),
        content: const Text("이 일정을 정말 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('official_calendar').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("일정이 삭제되었습니다.")));
      }
    }
  }

  Widget _buildLogoIcon(String? logoKey) {
    if (logoKey == null || logoKey == 'none') {
      return Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
        child: const Icon(Icons.emoji_events_outlined, size: 18, color: Colors.grey),
      );
    }
    return Container(
      width: 38, height: 38,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logos/$logoKey.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 16),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'domestic': return Colors.blueAccent;
      case 'overseas': return Colors.redAccent;
      case 'league': return Colors.greenAccent[700]!;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CommonAppBar(title: '공식 일정 달력', showBackButton: true),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('official_calendar').snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            return Column(
              children: [
                // [달력 카드 섹션]
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2025, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                    locale: 'ko_KR',
                    rowHeight: 52,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    holidayPredicate: (day) => day.weekday == DateTime.sunday,
                    eventLoader: (day) {
                      return docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final start = (data['startDate'] as Timestamp).toDate();
                        final end = (data['endDate'] as Timestamp).toDate();
                        final target = DateTime(day.year, day.month, day.day);
                        final cStart = DateTime(start.year, start.month, start.day);
                        final cEnd = DateTime(end.year, end.month, end.day);
                        return (target.isAtSameMomentAs(cStart) || target.isAtSameMomentAs(cEnd) || (target.isAfter(cStart) && target.isBefore(cEnd)));
                      }).toList();
                    },
                    calendarBuilders: CalendarBuilders(
                      // ✅ 토요일 파란색 설정
                      defaultBuilder: (context, day, focusedDay) {
                        if (day.weekday == DateTime.saturday) {
                          return Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500),
                            ),
                          );
                        }
                        return null;
                      },
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return const SizedBox.shrink();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: events.take(4).map((event) {
                            final data = (event as QueryDocumentSnapshot).data() as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0.5),
                              width: 5, height: 5,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: _getTypeColor(data['type'] ?? 'domestic')),
                            );
                          }).toList(),
                        );
                      },
                      todayBuilder: (context, date, _) => Center(child: Container(width: 36, height: 36, decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Center(child: Text('${date.day}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))))),
                      selectedBuilder: (context, date, _) => Center(child: Container(width: 36, height: 36, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(10)), child: Center(child: Text('${date.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: false,
                      defaultTextStyle: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                      // ✅ 일요일 빨간색 & 테두리 제거
                      holidayTextStyle: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      holidayDecoration: BoxDecoration(color: Colors.transparent),
                      weekendTextStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                // 리스트 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        "${_selectedDay!.month}월 ${_selectedDay!.day}일 일정",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // [리스트 섹션]
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: _buildSimpleEventList(_selectedDay!, docs, user),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSimpleEventList(DateTime date, List<QueryDocumentSnapshot> allDocs, User? user) {
    final filteredDocs = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final start = (data['startDate'] as Timestamp).toDate();
      final end = (data['endDate'] as Timestamp).toDate();
      final target = DateTime(date.year, date.month, date.day);
      final cStart = DateTime(start.year, start.month, start.day);
      final cEnd = DateTime(end.year, end.month, end.day);
      return (target.isAtSameMomentAs(cStart) || target.isAtSameMomentAs(cEnd) || (target.isAfter(cStart) && target.isBefore(cEnd)));
    }).toList();

    if (filteredDocs.isEmpty) {
      return const Center(child: Text("예정된 공식 일정이 없습니다.", style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 16, bottom: 30),
      itemCount: filteredDocs.length,
      separatorBuilder: (context, index) => Divider(height: 1, indent: 72, color: Colors.grey[100]),
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        final data = doc.data() as Map<String, dynamic>;
        final logoKey = data['logoKey'];

        return InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                _buildLogoIcon(logoKey),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'],
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (data['venue'] != null && data['venue'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // ✅ 장소 아이콘 추가
                            const Icon(Icons.place_outlined, size: 14, color: Colors.blueAccent),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                data['venue'],
                                style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
                if (user?.uid == adminUid)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                    onPressed: () => _deleteEvent(doc.id),
                  )
                else
                  const Icon(Icons.chevron_right, size: 20, color: Color(0xFFE2E8F0)),
              ],
            ),
          ),
        );
      },
    );
  }
}