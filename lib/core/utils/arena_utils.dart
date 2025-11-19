import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum EntryStatus {
  upcoming,    // 엔트리 예정
  open,        // 엔트리 오픈 중
  closed,      // 엔트리 마감
  finished,    // 대회 종료 (eventDate 지남)
}

class ArenaUtils {
  /// 오늘 기준으로 엔트리 상태 계산
  static EntryStatus getEntryStatus({
    required Timestamp eventDate,
    required Timestamp entryStartDate,
    required Timestamp entryEndDate,
  }) {
    final now = DateTime.now();

    final event = eventDate.toDate();
    final start = entryStartDate.toDate();
    final end = entryEndDate.toDate();

    if (now.isBefore(start)) {
      return EntryStatus.upcoming;
    } else if (now.isBefore(end.add(const Duration(minutes: 1)))) {
      return EntryStatus.open;
    } else if (now.isBefore(event)) {
      return EntryStatus.closed;
    } else {
      return EntryStatus.finished;
    }
  }

  /// 상태별 뱃지 텍스트
  static String getStatusText(EntryStatus status) {
    switch (status) {
      case EntryStatus.upcoming:
        return '엔트리 예정';
      case EntryStatus.open:
        return '엔트리 오픈';
      case EntryStatus.closed:
        return '엔트리 마감';
      case EntryStatus.finished:
        return '종료';
    }
  }

  /// 상태별 색상
  static Color getStatusColor(EntryStatus status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case EntryStatus.upcoming:
        return Colors.orange.shade600;
      case EntryStatus.open:
        return Colors.green.shade600;
      case EntryStatus.closed:
        return Colors.red.shade600;
      case EntryStatus.finished:
        return Colors.grey.shade600;
    }
  }

  /// D-Day 계산 (엔트리 마감 기준)
  static String getEntryDday(Timestamp entryEndDate) {
    final end = entryEndDate.toDate();
    final now = DateTime.now();
    final diff = end.difference(now);

    if (diff.isNegative) {
      return '마감됨';
    }

    if (diff.inDays > 0) {
      return 'D-${diff.inDays}';
    } else if (diff.inHours > 0) {
      return 'D-${diff.inHours}시간';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 남음';
    } else {
      return '곧 마감';
    }
  }

  /// 대회일 D-Day
  static String getEventDday(Timestamp eventDate) {
    final event = eventDate.toDate();
    final now = DateTime.now();
    final diff = event.difference(now).inDays;

    if (diff > 0) {
      return 'D-$diff';
    } else if (diff == 0) {
      return '오늘!';
    } else {
      return '종료됨';
    }
  }
}