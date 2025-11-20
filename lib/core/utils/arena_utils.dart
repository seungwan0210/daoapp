// lib/core/utils/arena_utils.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 한국 시간(KST) 기준 현재 Timestamp 반환
Timestamp get kstNow => Timestamp.fromDate(
  DateTime.now().toUtc().add(const Duration(hours: 9)),
);

/// 한국 시간 기준 DateTime.now() → 함수형 getter
DateTime nowKst() => DateTime.now().toUtc().add(const Duration(hours: 9));

enum EntryStatus {
  upcoming,     // 엔트리 시작 전
  open,         // 엔트리 진행 중
  closed,       // 엔트리 마감 ~ 대회 전날
  inProgress,   // 대회 당일
  finished,     // 대회 종료
  canceled,     // 취소됨
}

class ArenaUtils {
  /// 현재 상태 계산 (클라이언트 기준 한국시간 정확히 반영)
  static EntryStatus getEntryStatus({
    required Timestamp entryStartDate,
    required Timestamp entryEndDate,
    required Timestamp eventDate,
  }) {
    final now = nowKst(); // 여기만 고치면 됨!!

    if (now.isBefore(entryStartDate.toDate())) return EntryStatus.upcoming;
    if (now.isBefore(entryEndDate.toDate().add(const Duration(minutes: 1)))) {
      return EntryStatus.open;
    }
    if (now.isBefore(eventDate.toDate())) return EntryStatus.closed;
    if (now.isBefore(eventDate.toDate().add(const Duration(days: 1)))) {
      return EntryStatus.inProgress;
    }
    return EntryStatus.finished;
  }

  /// 상태별 텍스트
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

  /// 상태별 색상
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

  /// 엔트리 마감 D-Day
  static String entryDday(Timestamp entryEndDate) {
    final end = entryEndDate.toDate();
    final now = nowKst();
    final diff = end.difference(now);

    if (diff.isNegative) return '마감됨';

    final days = diff.inDays;
    if (days > 0) return 'D-$days';
    if (diff.inHours > 0) return '${diff.inHours}시간 남음';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 남음';
    return '곧 마감';
  }

  /// 대회 당일 D-Day
  static String eventDday(Timestamp eventDate) {
    final event = eventDate.toDate();
    final now = nowKst();
    final diff = event.difference(now).inDays;

    if (diff > 0) return 'D-$diff';
    if (diff == 0) return '오늘!';
    return '종료됨';
  }
}