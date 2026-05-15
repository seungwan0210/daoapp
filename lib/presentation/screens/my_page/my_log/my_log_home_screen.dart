import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/screens/my_page/my_log/my_log_write_screen.dart';
import 'package:daoapp/presentation/providers/my_log_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/presentation/screens/my_page/my_log/my_log_detail_screen.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class MyLogHomeScreen extends StatelessWidget {
  const MyLogHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return Scaffold(
            appBar: CommonAppBar(title: s.mylog_title), // 🔹 다국어 적용
            body: _buildLoginPrompt(context, s), // 🔹 s 전달
          );
        }

        return const _MyLogAuthedBody();
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context, AppLocalizations s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              s.mylog_login_required_title, // 🔹 다국어 적용
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              s.mylog_login_required_subtitle, // 🔹 다국어 적용
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, RouteConstants.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[600],
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(s.mylog_login_btn, // 🔹 다국어 적용
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyLogAuthedBody extends ConsumerWidget {
  const _MyLogAuthedBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final myLogsAsync = ref.watch(myLogProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CommonAppBar(title: s.mylog_title), // 🔹 다국어 적용
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F172A),
        child: const Icon(Icons.edit_note_rounded, color: Colors.cyanAccent, size: 30),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MyLogWriteScreen(initialDate: DateTime.now())),
        ),
      ),
      body: myLogsAsync.when(
        data: (logs) {
          final loggedDates = logs.map((log) => DateTime(log.date.year, log.date.month, log.date.day)).toSet();
          final sortedLogs = [...logs]..sort((a, b) => b.date.compareTo(a.date));
          final streakDays = _calculateCurrentStreak(loggedDates);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _buildModernSummaryCard(logs.length, streakDays, s), // 🔹 s 전달
              const SizedBox(height: 20),
              _buildModernCalendar(context, loggedDates, logs, s), // 🔹 s 전달
              const SizedBox(height: 28),
              if (sortedLogs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    s.mylog_recent_title, // 🔹 다국어 적용
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                  ),
                ),
                ...sortedLogs.take(5).map((log) => _buildRecentLogTile(context, log, s)), // 🔹 s 전달
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
        error: (_, __) => Center(child: Text(s.mylog_error_load)), // 🔹 다국어 적용
      ),
    );
  }

  Widget _buildModernSummaryCard(int total, int streak, AppLocalizations s) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF334155)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 65, height: 65,
                  child: CircularProgressIndicator(
                    value: (total % 30) / 30,
                    strokeWidth: 5,
                    color: Colors.cyanAccent,
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                ),
                const Text('🎯', style: TextStyle(fontSize: 26)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.mylog_summary_title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(s.mylog_summary_count(total), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)), // 🔹 파라미터 적용
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.mylog_summary_streak(streak), // 🔹 파라미터 적용
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCalendar(BuildContext context, Set<DateTime> loggedDates, List<MyLogModel> logs, AppLocalizations s) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: DateTime.now(),
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: {CalendarFormat.month: s.mylog_calendar_month_label}, // 🔹 다국어 적용
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.cyanAccent),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.cyanAccent),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Colors.white54, fontSize: 11),
            weekendStyle: TextStyle(color: Color(0xFFF87171), fontSize: 11),
          ),
          calendarStyle: const CalendarStyle(
            defaultTextStyle: TextStyle(color: Colors.white, fontSize: 13),
            weekendTextStyle: TextStyle(color: Color(0xFFFECACA), fontSize: 13),
            todayDecoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
            todayTextStyle: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
            outsideDaysVisible: false,
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final normalized = DateTime(date.year, date.month, date.day);
              if (loggedDates.contains(normalized)) {
                return Center(
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.6), width: 1.2),
                      shape: BoxShape.circle,
                      color: Colors.cyanAccent.withOpacity(0.08),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          onDaySelected: (selectedDay, _) => _handleDateSelection(context, selectedDay, logs, s), // 🔹 s 전달
        ),
      ),
    );
  }

  Widget _buildRecentLogTile(BuildContext context, MyLogModel log, AppLocalizations s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyLogDetailScreen(logId: log.id!))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (log.photoUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(log.photoUrls.first, width: 50, height: 50, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.grey, size: 20),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatFullDate(log.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      log.content ?? s.mylog_no_content, // 🔹 다국어 적용
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDateSelection(BuildContext context, DateTime selectedDay, List<MyLogModel> logs, AppLocalizations s) async {
    final selected = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final existingLog = logs.cast<MyLogModel?>().firstWhere(
          (l) => l != null && DateTime(l.date.year, l.date.month, l.date.day) == selected,
      orElse: () => null,
    );

    if (existingLog != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MyLogDetailScreen(logId: existingLog.id!)));
    } else {
      final confirm = await _showWriteConfirmSheet(context, selected, s); // 🔹 s 전달
      if (confirm == true) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MyLogWriteScreen(initialDate: selected)));
      }
    }
  }

  Future<bool?> _showWriteConfirmSheet(BuildContext context, DateTime date, AppLocalizations s) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.mylog_confirm_sheet_title(date.year, date.month, date.day), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // 🔹 파라미터 적용
              const SizedBox(height: 8),
              Text(s.mylog_confirm_sheet_body, style: const TextStyle(fontSize: 14, color: Colors.black87)), // 🔹 다국어 적용
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(s.mylog_confirm_sheet_btn_later), // 🔹 다국어 적용
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(s.mylog_confirm_sheet_btn_write, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // 🔹 다국어 적용
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateCurrentStreak(Set<DateTime> loggedDates) {
    if (loggedDates.isEmpty) return 0;
    final sorted = loggedDates.toList()..sort((a, b) => b.compareTo(a));
    int streak = 1;
    for (int i = 0; i < sorted.length - 1; i++) {
      if (sorted[i].difference(sorted[i + 1]).inDays == 1) streak++;
      else break;
    }
    return streak;
  }

  String _formatFullDate(DateTime date) {
    const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.year}년 ${date.month}월 ${date.day}일 (${weekDays[date.weekday - 1]})';
  }
}