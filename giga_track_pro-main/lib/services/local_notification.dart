import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:trackerapp/main.dart';
import 'package:trackerapp/models/event_on_map_model.dart';
import 'package:trackerapp/utils/logger.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications',
    importance: Importance.high,
  );

  /// INIT
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
      AppLogger.info('📍 Timezone set to: Asia/Karachi');
    } catch (e) {
      AppLogger.warning('⚠️ Could not set local timezone');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(_channel);
    await androidImpl?.requestNotificationsPermission();
  }

  /// FCM NOTIFICATION SHOW
  static Future<void> showFromRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final Map<String, dynamic> combinedData = Map<String, dynamic>.from(message.data);
    if (notification.title != null) combinedData['title'] = notification.title;
    if (notification.body != null) combinedData['body'] = notification.body;

    final payloadStr = jsonEncode(combinedData);

    await _plugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: _notificationDetails(),
      payload: payloadStr,
    );
  }

  /// MANUAL SHOW
  static Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final Map<String, dynamic> combinedData = Map<String, dynamic>.from(data ?? {});
    combinedData['title'] = title;
    combinedData['body'] = body;

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
      payload: jsonEncode(combinedData),
    );
  }

  /// SCHEDULED NOTIFICATION
  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) {
        AppLogger.warning('⚠️ Cannot schedule in the past: $scheduledDate');
        return;
      }

      final delay = scheduledDate.difference(now);
      final scheduledTZ = tz.TZDateTime.now(tz.local).add(delay);

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTZ,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      AppLogger.success('✅ Notification successfully queued in OS');
    } catch (e) {
      AppLogger.error('❌ Scheduling failed', e);
      try {
        final delay = scheduledDate.difference(DateTime.now());
        final scheduledTZ = tz.TZDateTime.now(tz.local).add(delay);
        
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledTZ,
          notificationDetails: _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e2) {
        AppLogger.error('❌ All scheduling attempts failed', e2);
      }
    }
  }

  /// DETAILS
  static NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'Used for important notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(payload);
        final model = EventOnMapDataModel.fromNotificationData(
          data,
          title: data['title']?.toString(),
          body: data['body']?.toString(),
        );

        MyApp.navigatorKey.currentState?.pushNamed(
          RoutesName.eventondevicemap,
          arguments: model,
        );
      } catch (e) {
        AppLogger.error('Error handling notification tap', e);
      }
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(payload);
        final model = EventOnMapDataModel.fromNotificationData(
          data,
          title: data['title']?.toString(),
          body: data['body']?.toString(),
        );

        MyApp.navigatorKey.currentState?.pushNamed(
          RoutesName.eventondevicemap,
          arguments: model,
        );
      } catch (e) {
        AppLogger.error('Error handling background notification tap', e);
      }
    }
  }
}
