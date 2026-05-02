import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class PracticeNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // ✅ iOS(Darwin) 초기화 설정 추가
    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin, // ✅ iOS 적용
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // 안드로이드 권한 요청
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// 실시간 알림 표시 및 3, 6, 9, 12시간 뒤 확인 알림 예약
  static Future<void> showPracticeNotification({
    required String shopName,
    required DateTime startTime,
  }) async {
    // 1. 안드로이드용 실시간 알림 설정 (상태 표시줄 상주)
    const androidDetails = AndroidNotificationDetails(
      'practice_session_channel',
      '연습 기록 알림',
      channelDescription: '다트 연습 세션의 실시간 시간을 표시합니다.',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      usesChronometer: true,
      color: Color(0xFF0F172A),
    );

    // ✅ iOS용 실시간 알림 설정 (iOS는 크로노미터 대신 일반 알림으로 표시)
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false, // 연습 중 계속 소리 나지 않게 설정
    );

    await _notificationsPlugin.show(
      888,
      '🎯 연습 기록 중: $shopName',
      '경과 시간을 확인하세요.',
      const NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails, // ✅ iOS 적용
      ),
    );

    // 2. 배포용 확인 알림 예약 (3, 6, 9, 12시간)
    for (int i = 1; i <= 4; i++) {
      int hours = i * 3;
      await _scheduleCheckNotification(hours, shopName);
    }
  }

  /// 시간 단위 예약 로직 (iOS 호환 버전)
  static Future<void> _scheduleCheckNotification(int hours, String shopName) async {
    final scheduleTime = tz.TZDateTime.now(tz.local).add(Duration(hours: hours));

    await _notificationsPlugin.zonedSchedule(
      888 + hours,
      '아직 연습 중이신가요? 🤔',
      '연습 시작 후 $hours시간이 지났습니다. 기록 종료를 잊으셨다면 앱에서 종료해주세요!',
      scheduleTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'practice_check_channel',
          '연습 확인 알림',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.orange,
        ),
        // ✅ iOS 확인 알림 설정 (소리와 배지 허용)
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 연습 종료 시 모든 알림 취소
  static Future<void> cancelNotification() async {
    await _notificationsPlugin.cancel(888);
    await _notificationsPlugin.cancel(891);
    await _notificationsPlugin.cancel(894);
    await _notificationsPlugin.cancel(897);
    await _notificationsPlugin.cancel(900);
  }
}