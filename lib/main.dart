import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grim_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:grim_app/app/modules/execution/controllers/execution_controller.dart';
import 'package:grim_app/app/modules/goals/controllers/goals_controller.dart';
import 'package:grim_app/app/modules/settings/controllers/settings_controller.dart';
import 'package:grim_app/app/routes/app_pages.dart';
import 'package:grim_app/app/services/notification_service.dart';
import 'package:grim_app/app/services/background_service.dart';
import 'package:grim_app/app/services/fullscreen_reminder_service.dart';
import 'package:grim_app/app/services/strict_mode_service.dart';
import 'package:grim_app/app/utils/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Initialize services first (dependencies)
  Get.put(NotificationService());
  Get.put(StrictModeService());

  // Initialize controllers after services
  Get.put(ThemeController());
  // DashboardController must be initialized before ExecutionController which depends on it
  Get.lazyPut(() => DashboardController());
  Get.put(ExecutionController());
  Get.put(GoalsController());
  Get.put(SettingsController());

  // Initialize background service for alarms when app is closed
  final backgroundService = BackgroundService();
  await backgroundService.initialize();

  // Initialize fullscreen reminder service for screen takeover
  final fullscreenService = FullscreenReminderService();
  await fullscreenService.initialize();

  runApp(const GrimExecutionApp());
}

class GrimExecutionApp extends StatelessWidget {
  const GrimExecutionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: 'Grim Execution',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeController.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
      ),
    );
  }
}
