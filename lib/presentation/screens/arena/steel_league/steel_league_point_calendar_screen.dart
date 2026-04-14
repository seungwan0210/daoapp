// lib/presentation/screens/arena/steel_league/steel_league_point_calendar_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/data/repositories/point_record_repository.dart';
import 'package:daoapp/data/models/point_record_model.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SteelLeaguePointCalendarScreen extends StatefulWidget {
  const SteelLeaguePointCalendarScreen({super.key});

  @override
  State<SteelLeaguePointCalendarScreen> createState() =>
      _SteelLeaguePointCalendarScreenState();
}

class _SteelLeaguePointCalendarScreenState
    extends State<SteelLeaguePointCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<PointRecord>> _events = {};

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  StreamSubscription<List<PointRecord>>? _eventsSub;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllPointEvents();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPointEvents() async {
    final repo = sl<PointRecordRepository>();
    _eventsSub?.cancel();
    _eventsSub = repo.getAllPointRecords().listen((records) {
      final Map<DateTime, List<PointRecord>> events = {};
      for (var record in records) {
        final date = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );
        events.putIfAbsent(date, () => []).add(record);
      }
      if (!mounted) return;
      setState(() => _events = events);
    });
  }

  List<PointRecord> _getEventsForDay(DateTime day) {
    final events = _events[DateTime(day.year, day.month, day.day)] ?? [];
    return _sortAndRank(events);
  }

  List<PointRecord> _getSearchResults(List<PointRecord> allRecords) {
    if (_searchQuery.isEmpty) return [];
    return allRecords
        .where((r) =>
    r.koreanName.toLowerCase().contains(_searchQuery) ||
        r.englishName.toLowerCase().contains(_searchQuery))
        .toList();
  }

  List<PointRecord> _sortAndRank(List<PointRecord> events) {
    events.sort((a, b) => b.points.compareTo(a.points));
    int currentRank = 1;
    int? previousPoints;
    for (int i = 0; i < events.length; i++) {
      if (i == 0) {
        currentRank = 1;
      } else if (events[i].points == previousPoints!) {
        // 동점이면 같은 랭크 유지
      } else {
        currentRank = i + 1;
      }
      events[i] = events[i].copyWith(rank: currentRank);
      previousPoints = events[i].points;
    }
    return events;
  }

  void _startSearch() {
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  // 시즌/통합 라벨 텍스트
  String _buildSeasonLabel(PointRecord record) {
    final seasonId = record.seasonId; // 예: '2026'
    switch (record.phase) {
      case 'season1':
        return '$seasonId 시즌 1';
      case 'season2':
        return '$seasonId 시즌 2';
      case 'season3':
        return '$seasonId 시즌 3';
      case 'total':
        return '$seasonId 통합';
      default:
        return record.phase;
    }
  }

  // 시즌/통합 칩 색상
  Color _phaseColor(String phase) {
    switch (phase) {
      case 'season1':
        return Colors.blueAccent;
      case 'season2':
        return Colors.purple;
      case 'season3':
        return Colors.teal;
      case 'total':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = sl<PointRecordRepository>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: _isSearching ? '' : '스틸리그 포인트 달력',
        showBackButton: true,
        actions: _isSearching
            ? null
            : [
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: _startSearch,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 검색바
          if (_isSearching)
            SliverToBoxAdapter(
              child: Container(
                color: theme.colorScheme.primaryContainer.withOpacity(0.95),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '이름 검색 (한글/영어)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _stopSearch,
                    ),
                  ),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),

          // 달력
          SliverToBoxAdapter(
            child: AppCard(
              margin: const EdgeInsets.all(16),
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: SizedBox(
                height: 400,
                child: TableCalendar(
                  firstDay: AppDateUtils.firstDay,
                  lastDay: AppDateUtils.lastDay,
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!_isSearching) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) =>
                      setState(() => _focusedDay = focusedDay),
                  eventLoader: _getEventsForDay,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    titleTextStyle: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle),
                    todayTextStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    selectedDecoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        shape: BoxShape.circle),
                    selectedTextStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // 리스트
          _isSearching
              ? SliverFillRemaining(
            hasScrollBody: true,
            child: StreamBuilder<List<PointRecord>>(
              stream: repo.getAllPointRecords(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final allRecords = snapshot.data!;
                final searchResults = _getSearchResults(allRecords);
                final sortedResults = _sortAndRank(searchResults);
                if (sortedResults.isEmpty) {
                  return const Center(child: Text('검색 결과 없음'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedResults.length,
                  itemBuilder: (_, i) {
                    final record = sortedResults[i];
                    final rank = record.rank ?? i + 1;
                    return _buildRecordCardWithBadge(
                        context, theme, record, rank);
                  },
                );
              },
            ),
          )
              : _selectedDay == null
              ? const SliverFillRemaining(
            child: Center(child: Text('날짜를 선택하세요')),
          )
              : _getEventsForDay(_selectedDay!).isEmpty
              ? const SliverFillRemaining(
            child: Center(child: Text('해당 날짜에 포인트 내역 없음')),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (_, i) {
                final record =
                _getEventsForDay(_selectedDay!)[i];
                final rank = record.rank ?? i + 1;
                return _buildRecordCardWithBadge(
                    context, theme, record, rank);
              },
              childCount:
              _getEventsForDay(_selectedDay!).length,
            ),
          ),
        ],
      ),
    );
  }

  // 배지 포함 카드
  Widget _buildRecordCardWithBadge(
      BuildContext context, ThemeData theme, PointRecord record, int rank) {
    final dateStr =
        '${record.date.year}.${record.date.month.toString().padLeft(2, '0')}.${record.date.day.toString().padLeft(2, '0')}';
    final seasonLabel = _buildSeasonLabel(record);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        elevation: 3,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rank == 1
                        ? Colors.amber
                        : rank == 2
                        ? Colors.grey
                        : rank == 3
                        ? Colors.brown.shade600
                        : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름 + 배지
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.koreanName,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 배지 (이름 옆)
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(record.userId)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            final userData = snapshot.data!.data()
                            as Map<String, dynamic>? ??
                                {};
                            final badgesMap =
                            BadgeUtils.extractBadges(userData);
                            final monthly =
                            BadgeUtils.getLatestMonthlyBadge(badgesMap);
                            final admin =
                            BadgeUtils.getLatestAdminBadge(badgesMap);
                            final badges = <String>[];
                            if (monthly != null) badges.add(monthly);
                            if (admin != null) badges.add(admin);

                            return Wrap(
                              spacing: 2,
                              children: badges
                                  .map(
                                    (key) => Tooltip(
                                  message:
                                  BadgeUtils.getBadgeTooltip(key),
                                  child: BadgeWidget(
                                    badgeKey: key,
                                    size: 18,
                                  ),
                                ),
                              )
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                    // 영어 이름
                    Text(
                      record.englishName,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // 날짜 + 시즌(통합/시즌1/2/3) 라벨 → Wrap으로 overflow 방지
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _phaseColor(record.phase).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _phaseColor(record.phase),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            seasonLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _phaseColor(record.phase),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  record.shopName,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
      ),
    );
  }
}
