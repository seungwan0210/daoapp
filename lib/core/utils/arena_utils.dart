// lib/core/utils/arena_utils.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 한국 시간(KST) 기준 현재 Timestamp 반환
Timestamp get kstNow => Timestamp.fromDate(
  DateTime.now().toUtc().add(const Duration(hours: 9)),
);

/// 한국 시간 기준 DateTime.now()
DateTime nowKst() => DateTime.now().toUtc().add(const Duration(hours: 9));

enum EntryStatus {
  upcoming,     // 엔트리 시작 전
  open,         // 엔트리 진행 중
  closed,       // 엔트리 마감 ~ 대회 전
  inProgress,   // 대회 당일 진행 중
  finished,     // 대회 종료
  canceled,     // 취소됨 (추후 확장용)
}

class ArenaUtils {
  /// 현재 대회 상태 계산 (클라이언트 기준 한국시간 반영)
  static EntryStatus getEntryStatus({
    required Timestamp entryStartDate,
    required Timestamp entryEndDate,
    required Timestamp eventDate,
  }) {
    final now = nowKst();

    // 엔트리 시작 전
    if (now.isBefore(entryStartDate.toDate())) {
      return EntryStatus.upcoming;
    }

    // 엔트리 진행 중 (마감 시간 + 1분 버퍼)
    if (now.isBefore(entryEndDate.toDate().add(const Duration(minutes: 1)))) {
      return EntryStatus.open;
    }

    // 엔트리 마감 ~ 대회 전날까지
    if (now.isBefore(eventDate.toDate())) {
      return EntryStatus.closed;
    }

    // 대회 당일
    if (now.isBefore(eventDate.toDate().add(const Duration(days: 1)))) {
      return EntryStatus.inProgress;
    }

    // 그 이후는 종료
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

  /// 엔트리 마감까지 남은 시간 (가장 많이 쓰이는 핵심 함수)
  /// 예: D-5, 3시간 남음, 마감됨
  static String entryDday(Timestamp target) {
    final targetDateTime = target.toDate();
    final now = nowKst();

    // 날짜만 비교 (시간 오차 제거)
    final targetDateOnly = DateTime(targetDateTime.year, targetDateTime.month, targetDateTime.day);
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    final diffDays = targetDateOnly.difference(todayDateOnly).inDays;

    if (diffDays < 0) return '마감됨';
    if (diffDays > 0) return 'D-$diffDays';

    // 오늘 마감 → 시간/분 단위로 표시
    final diff = targetDateTime.difference(now);
    if (diff.isNegative) return '마감됨';

    if (diff.inHours > 0) return '${diff.inHours}시간 남음';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 남음';

    return '곧 마감';
  }

  /// 엔트리 시작일까지 남은 날 (엔트리 예정 상태에서만 사용)
  /// 예: D-7, 오늘 시작!, 진행 중
  static String entryStartDday(Timestamp entryStartDate) {
    final start = entryStartDate.toDate();
    final now = nowKst();

    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(start.year, start.month, start.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays > 0) return 'D-$diffDays';
    if (diffDays == 0) return '오늘 시작!';
    return '진행 중';
  }

  /// 대회 당일까지 남은 날 (대회일 기준)
  /// 예: D-10, 오늘!, 종료됨
  static String eventDday(Timestamp eventDate) {
    final event = eventDate.toDate();
    final now = nowKst();

    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(event.year, event.month, event.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays > 0) return 'D-$diffDays';
    if (diffDays == 0) return '오늘!';
    return '종료됨';
  }
}