import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final Set<String> _notified = {};

  static Future<void> init() async {
    if (kIsWeb || _initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  static void resetSession() => _notified.clear();

  static bool _once(String key) {
    if (_notified.contains(key)) return false;
    _notified.add(key);
    return true;
  }

  static Future<void> showLiberado(String userId, String nome, String? faculdade) async {
    if (kIsWeb || !_initialized) return;
    if (!_once('lib_$userId')) return;
    await _plugin.show(
      userId.hashCode.abs() % 100000,
      '$nome foi liberado! 🎉',
      faculdade?.isNotEmpty == true ? 'Saindo de $faculdade' : 'Pronto para embarcar',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vango_lib', 'Liberações',
          channelDescription: 'Alertas quando alunos são liberados da faculdade',
          importance: Importance.high, priority: Priority.high,
          playSound: true, enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  static Future<void> showDriverApproaching() async {
    if (kIsWeb || !_initialized) return;
    if (!_once('driver_near')) return;
    await _plugin.show(
      999,
      'A van está chegando! 🚐',
      'O motorista está a menos de 500m de você',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vango_prox', 'Proximidade',
          channelDescription: 'Alerta quando o motorista está próximo',
          importance: Importance.high, priority: Priority.high, playSound: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  static void resetDriverApproaching() => _notified.remove('driver_near');
}
