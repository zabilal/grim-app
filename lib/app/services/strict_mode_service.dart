import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../modules/settings/controllers/settings_controller.dart';
import 'app_blocker_channel.dart';

class StrictModeService extends GetxService {
  static final StrictModeService _instance = StrictModeService._internal();
  factory StrictModeService() => _instance;
  StrictModeService._internal();

  final storage = GetStorage();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Timer? _strictModeTimer;
  final isStrictModeActive = false.obs;
  final blockedApps = <String>[].obs;

  // Default blocked social media apps (package names)
  final defaultBlockedApps = [
    'com.facebook.katana', // Facebook
    'com.instagram.android', // Instagram
    'com.twitter.android', // Twitter
    'com.tiktok', // TikTok
    'com.snapchat.android', // Snapchat
    'com.reddit.frontpage', // Reddit
    'com.whatsapp', // WhatsApp
    'com.discord', // Discord
    'com.linkedin.android', // LinkedIn
    'com.pinterest', // Pinterest
    'com.spotify.music', // Spotify
    'com.netflix.mediaclient', // Netflix
    'com.youtube.android', // YouTube
    'com.google.android.youtube', // YouTube (alternative)
    'com.zhiliaoapp.musically', // TikTok (alternative)
  ];

  @override
  void onInit() {
    super.onInit();
    _initializeStrictMode();
    loadBlockedApps();
  }

  Future<void> _initializeStrictMode() async {
    // Initialize notifications for strict mode warnings
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

    // Create notification channel for strict mode
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'strict_mode',
      'Strict Mode',
      description: 'Notifications for strict mode enforcement',
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

  void loadBlockedApps() {
    final savedBlockedApps = storage.read('blockedApps') ?? defaultBlockedApps;
    blockedApps.assignAll(savedBlockedApps);
  }

  void saveBlockedApps() {
    storage.write('blockedApps', blockedApps.toList());
  }

  void toggleStrictMode() {
    final settingsController = Get.find<SettingsController>();
    settingsController.strictModeEnabled.value =
        !settingsController.strictModeEnabled.value;
    storage.write('strictMode', settingsController.strictModeEnabled.value);
  }

  Future<void> activateStrictMode(String taskType) async {
    if (!isStrictModeActive.value &&
        taskType.toLowerCase().contains('deep work')) {
      isStrictModeActive.value = true;

      // Check and request usage stats permission
      final hasPermission = await AppBlockerChannel.hasUsageStatsPermission();
      if (!hasPermission) {
        final granted = await AppBlockerChannel.requestUsageStatsPermission();
        if (!granted) {
          Get.snackbar(
            'Permission Required',
            'Usage stats permission is required for strict mode. Please enable it in settings.',
            backgroundColor: Colors.orange,
          );
          return;
        }
      }

      // Start native app blocker service
      await AppBlockerChannel.startAppBlocker(blockedApps.toList());

      // Start periodic checking as backup
      _strictModeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _checkForBlockedApps();
      });

      // Show strict mode activation notification
      await _showStrictModeNotification(true);
    }
  }

  Future<void> deactivateStrictMode() async {
    if (isStrictModeActive.value) {
      isStrictModeActive.value = false;
      _strictModeTimer?.cancel();

      // Stop native app blocker service
      await AppBlockerChannel.stopAppBlocker();

      // Show strict mode deactivation notification
      await _showStrictModeNotification(false);
    }
  }

  Future<void> _checkForBlockedApps() async {
    if (!isStrictModeActive.value) return;

    try {
      // This would require native code to check foreground app
      // For now, we'll show a warning notification periodically
      await _showStrictModeWarning();
    } catch (e) {
      print('Error checking blocked apps: $e');
    }
  }

  Future<void> _showStrictModeNotification(bool activating) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'strict_mode',
          'Strict Mode',
          channelDescription: 'Notifications for strict mode enforcement',
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

    await _notifications.show(
      9999, // Unique ID for strict mode notifications
      activating ? 'Strict Mode Activated' : 'Strict Mode Deactivated',
      activating
          ? 'Social media apps are now blocked during deep work.'
          : 'Strict mode has been deactivated.',
      platformChannelSpecifics,
    );
  }

  Future<void> _showStrictModeWarning() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'strict_mode',
          'Strict Mode',
          channelDescription: 'Notifications for strict mode enforcement',
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

    await _notifications.show(
      9998, // Different ID for warnings
      'Strict Mode Active',
      'Stay focused! Distractions are blocked during deep work.',
      platformChannelSpecifics,
    );
  }

  void addBlockedApp(String packageName) {
    if (!blockedApps.contains(packageName)) {
      blockedApps.add(packageName);
      saveBlockedApps();
    }
  }

  void removeBlockedApp(String packageName) {
    blockedApps.remove(packageName);
    saveBlockedApps();
  }

  void resetToDefaultBlockedApps() {
    blockedApps.assignAll(defaultBlockedApps);
    saveBlockedApps();
  }

  bool isAppBlocked(String packageName) {
    return blockedApps.contains(packageName);
  }

  @override
  void onClose() {
    _strictModeTimer?.cancel();
    super.onClose();
  }
}
