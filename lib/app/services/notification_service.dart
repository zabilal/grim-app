import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../modules/execution/controllers/execution_controller.dart';
import '../modules/execution/views/task_reminder_screen.dart';

class NotificationService extends GetxService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Timer? _reminderTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
    _startReminderTimer();
  }

  Future<void> _initializeNotifications() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
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

    // Create notification channel for Android
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
  }

  void _startReminderTimer() {
    // Check for reminders every minute
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkForDueTasks();
    });
  }

  Future<void> _checkForDueTasks() async {
    try {
      final executionController = Get.find<ExecutionController>();
      final now = DateTime.now();
      final currentHour = now.hour;
      final currentDay = _getDayString(now.weekday);

      final dueTasks = executionController.tasks
          .where(
            (task) =>
                task.day == currentDay &&
                task.startHour == currentHour &&
                !task.isCompleted &&
                task.hasReminder,
          )
          .toList();

      for (final task in dueTasks) {
        await _showTaskNotification(task);
      }
    } catch (e) {
      print('Error checking for due tasks: $e');
    }
  }

  Future<void> _showTaskNotification(dynamic task) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
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
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            'Time to execute: ${task.specificTask ?? task.taskType}',
            htmlFormatBigText: true,
            contentTitle: 'Task Reminder',
            htmlFormatContentTitle: true,
          ),
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      task.id.hashCode,
      'Task Reminder',
      'Time to execute: ${task.specificTask ?? task.taskType}',
      platformChannelSpecifics,
      payload: task.id.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null) {
      try {
        final executionController = Get.find<ExecutionController>();
        final taskId = int.parse(payload);
        final task = executionController.tasks.firstWhereOrNull(
          (t) => t.id == taskId,
        );

        if (task != null) {
          // Show the task reminder screen
          Get.to(
            () => TaskReminderScreen(task: task),
            fullscreenDialog: true,
            preventDuplicates: true,
          );
        }
      } catch (e) {
        print('Error handling notification tap: $e');
      }
    }
  }

  String _getDayString(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Future<void> scheduleTaskReminder(
    dynamic task,
    DateTime scheduledTime,
  ) async {
    await _notifications.zonedSchedule(
      task.id.hashCode,
      'Task Reminder',
      'Time to execute: ${task.specificTask ?? task.taskType}',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Notifications for task reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: task.id.toString(),
    );
  }

  Future<void> cancelTaskReminder(int taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  @override
  void onClose() {
    _reminderTimer?.cancel();
    super.onClose();
  }
}
