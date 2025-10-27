// lib/core/utils/date_utils.dart
import 'package:intl/intl.dart';

/// 날짜를 한국식으로 예쁘게 바꿔주는 도구
class DateUtils {
  static String 한국식_날짜(DateTime date) {
  return DateFormat('yyyy년 MM월 dd일').format(date);
  }

  static String 한국식_시간(DateTime date) {
  return DateFormat('a h시 mm분').format(date).replaceAll('AM', '오전').replaceAll('PM', '오후');
  }
}