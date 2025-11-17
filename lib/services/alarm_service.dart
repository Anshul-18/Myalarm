import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const platform = MethodChannel('flutter_alarmapp/alarm');
  
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap - stop the alarm sound
        await stopAlarmSound();
      },
    );
    
    // Request exact alarm permission for Android 12+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleAlarm(
    int id,
    String title,
    String body,
    DateTime scheduledTime, {
    String? ringtoneUri,
    String? displayTime,
  }) async {
    // Schedule notification
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarms',
          channelDescription: 'Channel for alarm notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: false, // Sound will be played by AlarmReceiver
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          ongoing: true,
          autoCancel: false,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'dismiss',
              'Dismiss',
              cancelNotification: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm.mp3',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: id.toString(),
    );
    
    // Schedule alarm sound using AlarmManager
    try {
      await platform.invokeMethod('scheduleAlarm', {
        'id': id,
        'timeInMillis': scheduledTime.millisecondsSinceEpoch,
        'time': displayTime ?? '',
      });
    } catch (e) {
      print('Error scheduling alarm sound: $e');
    }
  }

  static Future<void> playAlarmSound() async {
    // Not needed - handled by native code
  }

  static Future<void> stopAlarmSound() async {
    try {
      await platform.invokeMethod('stopAlarm');
    } catch (e) {
      print('Error stopping alarm: $e');
    }
  }

  static Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id);
    await stopAlarmSound();
    
    // Cancel native alarm
    try {
      await platform.invokeMethod('cancelAlarm', {'id': id});
    } catch (e) {
      print('Error cancelling native alarm: $e');
    }
  }
}
