import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> scheduleAppointmentReminder(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
  ) async {
    try {
      if (scheduledDate.isBefore(DateTime.now())) {
        throw Exception('Cannot schedule notification for past time');
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(
            scheduledDate.subtract(const Duration(hours: 1)), tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_channel',
            'Appointment Reminders',
            importance: Importance.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
      rethrow;
    }
  }
}
