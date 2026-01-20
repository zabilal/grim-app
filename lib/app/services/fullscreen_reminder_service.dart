import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/data/latest.dart' as tz;

class FullscreenReminderService {
  static final FullscreenReminderService _instance =
      FullscreenReminderService._internal();
  factory FullscreenReminderService() => _instance;
  FullscreenReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final storage = GetStorage();

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize notifications for fullscreen reminders
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create high-priority notification channel for fullscreen reminders
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fullscreen_reminders',
      'Fullscreen Task Reminders',
      description: 'High-priority task reminders that take over the screen',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Schedule periodic alarm for fullscreen checking
    await AndroidAlarmManager.periodic(
      const Duration(minutes: 1),
      1, // Alarm ID for fullscreen reminders
      _checkForFullscreenReminders,
      exact: true,
      wakeup: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _checkForFullscreenReminders() async {
    // This runs in the background even when app is closed
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    // Initialize notifications for background
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await notifications.initialize(initializationSettings);

    // Create fullscreen notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fullscreen_reminders',
      'Fullscreen Task Reminders',
      description: 'High-priority task reminders that take over the screen',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: false,
    );

    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    try {
      // Load tasks from storage
      final storage = GetStorage();
      final tasksData = storage.read('execution_tasks') ?? [];

      final now = DateTime.now();
      final currentHour = now.hour;
      final currentDay = _getDayString(now.weekday);

      for (final taskData in tasksData) {
        if (taskData['day'] == currentDay &&
            taskData['start_hour'] == currentHour &&
            !taskData['is_completed'] &&
            taskData['has_reminder']) {
          // Show fullscreen notification with full-screen intent
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
                'fullscreen_reminders',
                'Fullscreen Task Reminders',
                channelDescription:
                    'High-priority task reminders that take over the screen',
                importance: Importance.high,
                priority: Priority.high,
                showWhen: true,
                enableVibration: true,
                playSound: true,
                icon: '@mipmap/ic_launcher',
                category: AndroidNotificationCategory.alarm,
                visibility: NotificationVisibility.public,
                fullScreenIntent: true,
                autoCancel: false,
                ongoing: true,
              );

          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);

          await notifications.show(
            taskData['id'].hashCode,
            'TASK EXECUTION TIME',
            'Time to execute: ${taskData['specific_task'] ?? taskData['task_type']}',
            platformChannelSpecifics,
            payload: 'fullscreen_${taskData['id']}',
          );
        }
      }
    } catch (e) {
      print('Fullscreen reminder check error: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null && payload.startsWith('fullscreen_')) {
      // This will be handled by the main app when it opens
      // The fullscreen intent should already be showing the reminder
      print('Fullscreen reminder tapped: $payload');
    }
  }

  static String _getDayString(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Future<void> scheduleFullscreenAlarm(
    DateTime scheduledTime,
    int taskId,
    String taskTitle,
  ) async {
    await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      taskId + 1000, // Use different ID range for fullscreen alarms
      () => _showFullscreenTaskReminder(taskId, taskTitle),
      exact: true,
      wakeup: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _showFullscreenTaskReminder(
    int taskId,
    String taskTitle,
  ) async {
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await notifications.initialize(initializationSettings);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'fullscreen_reminders',
          'Fullscreen Task Reminders',
          channelDescription:
              'High-priority task reminders that take over the screen',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
          autoCancel: false,
          ongoing: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await notifications.show(
      taskId.hashCode,
      'TASK EXECUTION TIME',
      'Time to execute: $taskTitle',
      platformChannelSpecifics,
    );
  }

  Future<void> cancelFullscreenAlarm(int taskId) async {
    await AndroidAlarmManager.cancel(taskId + 1000);
    await _notifications.cancel(taskId.hashCode);
  }

  Future<void> cancelAllFullscreenAlarms() async {
    await AndroidAlarmManager.cancel(1);
    await _notifications.cancelAll();
  }
}
