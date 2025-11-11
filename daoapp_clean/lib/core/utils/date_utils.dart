// lib/core/utils/date_utils.dart
import 'package:intl/intl.dart';

class AppDateUtils {
  static DateTime get firstDay => DateTime(DateTime.now().year - 1, 1, 1);
  static DateTime get lastDay  => DateTime(DateTime.now().year + 2, 12, 31);
  static DateTime get today    => DateTime.now();

  static String formatKoreanDate(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일').format(date);
  }

  static String formatKoreanTime(DateTime date) {
    return DateFormat('a h시 mm분')
        .format(date)
        .replaceAll('AM', '오전')
        .replaceAll('PM', '오후');
  }

  static String formatKoreanDateTime(DateTime date) {
    return '${formatKoreanDate(date)} ${formatKoreanTime(date)}';
  }

  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}년 전';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}개월 전';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}