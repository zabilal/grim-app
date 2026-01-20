import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/data/latest.dart' as tz;

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final storage = GetStorage();

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize notifications for background
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

    await _notifications.initialize(initializationSettings);

    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Notifications for task reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Schedule periodic alarm for background checking
    await AndroidAlarmManager.periodic(
      const Duration(minutes: 1),
      0, // Alarm ID
      _checkForDueTasks,
      exact: true,
      wakeup: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _checkForDueTasks() async {
    // This runs in the background even when app is closed
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    // Initialize notifications for background
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await notifications.initialize(initializationSettings);

    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Notifications for task reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
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
          // Show notification
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
                'task_reminders',
                'Task Reminders',
                channelDescription: 'Notifications for task reminders',
                importance: Importance.high,
                priority: Priority.high,
                showWhen: true,
                enableVibration: true,
                playSound: true,
                icon: '@mipmap/ic_launcher',
              );

          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);

          await notifications.show(
            taskData['id'].hashCode,
            'Task Reminder',
            'Time to execute: ${taskData['specific_task'] ?? taskData['task_type']}',
            platformChannelSpecifics,
          );
        }
      }
    } catch (e) {
      print('Background task check error: $e');
    }
  }

  static String _getDayString(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Future<void> cancelAllAlarms() async {
    await AndroidAlarmManager.cancel(0);
  }

  Future<void> scheduleOneTimeAlarm(
    DateTime scheduledTime,
    int taskId,
    String taskTitle,
  ) async {
    await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      taskId,
      () => _showSpecificTaskReminder(taskId, taskTitle),
      exact: true,
      wakeup: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _showSpecificTaskReminder(
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
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Notifications for task reminders',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await notifications.show(
      taskId.hashCode,
      'Task Reminder',
      'Time to execute: $taskTitle',
      platformChannelSpecifics,
    );
  }
}
