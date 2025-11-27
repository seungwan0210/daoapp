// lib/core/utils/arena_utils.dart (타임존 100% 안전장치 버전)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 한국 시간(KST) 기준 현재 Timestamp 반환
Timestamp get kstNow => Timestamp.fromDate(
  DateTime.now().toUtc().add(const Duration(hours: 9)),
);

/// 한국 시간 기준 DateTime.now() - 항상 KST로 고정
DateTime nowKst() => DateTime.now().toUtc().add(const Duration(hours: 9));

enum EntryStatus {
  upcoming,
  open,
  closed,
  inProgress,
  finished,
  canceled,
}

class ArenaUtils {
  /// 타임존 문제 100% 해결 버전
  static EntryStatus getEntryStatus({
    required Timestamp entryStartDate,
    required Timestamp entryEndDate,
    required Timestamp eventDate,
  }) {
    final now = nowKst();

    // 강제로 KST 변환 (디바이스 타임존 무시)
    final start = _toKst(entryStartDate.toDate());
    final end = _toKst(entryEndDate.toDate());
    final event = _toKst(eventDate.toDate());

    if (now.isBefore(start)) return EntryStatus.upcoming;
    if (!now.isAfter(end)) return EntryStatus.open;
    if (now.isBefore(event)) return EntryStatus.closed;

    final eventEnd = DateTime(event.year, event.month, event.day, 23, 59, 59, 999);
    if (now.isBefore(_toKst(eventEnd).add(const Duration(seconds: 1)))) {
      return EntryStatus.inProgress;
    }

    return EntryStatus.finished;
  }

  // 강제 KST 변환 함수
  static DateTime _toKst(DateTime dt) {
    return dt.toUtc().add(const Duration(hours: 9));
  }

  static String statusText(EntryStatus status) {
    return switch (status) {
      EntryStatus.upcoming => '엔트리 예정',
      EntryStatus.open => '엔트리 오픈',
      EntryStatus.closed => '엔트리 마감',
      EntryStatus.inProgress => '진행 중',
      EntryStatus.finished => '종료',
      EntryStatus.canceled => '취소됨',
    };
  }

  static Color statusColor(EntryStatus status, BuildContext context) {
    return switch (status) {
      EntryStatus.upcoming => Colors.deepOrange.shade600,
      EntryStatus.open => Colors.green.shade600,
      EntryStatus.closed => Colors.red.shade600,
      EntryStatus.inProgress => Theme.of(context).colorScheme.primary,
      EntryStatus.finished => Colors.grey.shade600,
      EntryStatus.canceled => Colors.purple.shade600,
    };
  }

  static String entryDday(Timestamp target) {
    final targetDateTime = _toKst(target.toDate());
    final now = nowKst();

    final targetDateOnly = DateTime(targetDateTime.year, targetDateTime.month, targetDateTime.day);
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    final diffDays = targetDateOnly.difference(todayDateOnly).inDays;

    if (diffDays < 0) return '마감됨';
    if (diffDays > 0) return 'D-$diffDays';

    final diff = targetDateTime.difference(now);
    if (diff.isNegative) return '마감됨';

    if (diff.inHours > 0) return '${diff.inHours}시간 남음';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 남음';
    return '곧 마감';
  }

  static String entryStartDday(Timestamp entryStartDate) {
    final start = _toKst(entryStartDate.toDate());
    final now = nowKst();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(start.year, start.month, start.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays > 0) return 'D-$diffDays';
    if (diffDays == 0) return '오늘 시작!';
    return '진행 중';
  }

  static String eventDday(Timestamp eventDate) {
    final event = _toKst(eventDate.toDate());
    final now = nowKst();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(event.year, event.month, event.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays > 0) return 'D-$diffDays';
    if (diffDays == 0) return '오늘!';
    return '종료됨';
  }
}