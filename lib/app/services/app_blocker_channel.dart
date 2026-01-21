import 'package:flutter/services.dart';

class AppBlockerChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.zaktech.grim/app_blocker',
  );

  static Future<void> startAppBlocker(List<String> blockedApps) async {
    try {
      await _channel.invokeMethod('startAppBlocker', {
        'blockedApps': blockedApps,
      });
    } catch (e) {
      print('Error starting app blocker: $e');
    }
  }

  static Future<void> stopAppBlocker() async {
    try {
      await _channel.invokeMethod('stopAppBlocker');
    } catch (e) {
      print('Error stopping app blocker: $e');
    }
  }

  static Future<bool> requestUsageStatsPermission() async {
    try {
      final bool granted = await _channel.invokeMethod(
        'requestUsageStatsPermission',
      );
      return granted;
    } catch (e) {
      print('Error requesting usage stats permission: $e');
      return false;
    }
  }

  static Future<bool> hasUsageStatsPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod(
        'hasUsageStatsPermission',
      );
      return hasPermission;
    } catch (e) {
      print('Error checking usage stats permission: $e');
      return false;
    }
  }

  static Future<void> startNavigationBlock() async {
    try {
      await _channel.invokeMethod('startNavigationBlock');
    } catch (e) {
      print('Error starting navigation block: $e');
    }
  }

  static Future<void> stopNavigationBlock() async {
    try {
      await _channel.invokeMethod('stopNavigationBlock');
    } catch (e) {
      print('Error stopping navigation block: $e');
    }
  }
}
