import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 로컬 푸시 알림. 경고(이탈/끊김)와 정보(근접) 두 채널을 쓴다.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _alertChannel =
      AndroidNotificationChannel(
    'kid_guard_alert',
    '이탈 경고',
    description: '아이가 멀어지거나 신호가 끊겼을 때 울리는 경고',
    importance: Importance.max,
  );

  static const AndroidNotificationChannel _infoChannel =
      AndroidNotificationChannel(
    'kid_guard_info',
    '근접 알림',
    description: '상대가 가까워졌을 때 알림',
    importance: Importance.high,
  );

  Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestSoundPermission: true,
        requestBadgePermission: false,
      ),
    );
    await _plugin.initialize(settings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(_alertChannel);
      await android.createNotificationChannel(_infoChannel);
    }
  }

  /// 긴급 경고: 소리·진동·화면 켜기
  Future<void> showAlert(String title, String body) => _show(
        id: 1,
        title: title,
        body: body,
        channel: _alertChannel,
        critical: true,
      );

  /// 일반 정보 알림
  Future<void> showInfo(String title, String body) => _show(
        id: 2,
        title: title,
        body: body,
        channel: _infoChannel,
        critical: false,
      );

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required AndroidNotificationChannel channel,
    required bool critical,
  }) {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: critical ? Priority.max : Priority.high,
        category: critical
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.status,
        fullScreenIntent: critical,
        enableVibration: true,
        playSound: true,
        ticker: title,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: false,
        interruptionLevel: critical
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
    );
    return _plugin.show(id, title, body, details);
  }
}
