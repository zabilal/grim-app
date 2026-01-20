import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grim_app/app/data/models/execution_task.dart';
import 'package:grim_app/app/modules/execution/views/task_reminder_screen.dart';
import 'package:grim_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:grim_app/app/modules/settings/controllers/settings_controller.dart';
import 'package:grim_app/app/services/strict_mode_service.dart';

class ExecutionController extends GetxController {
  final storage = GetStorage();
  final tasks = <ExecutionTask>[].obs;
  final selectedDay = 'Mon'.obs;
  final topGoalsPerDay = <String, String>{}.obs;
  late TextEditingController topGoalController;

  @override
  void onInit() {
    super.onInit();
    topGoalController = TextEditingController();
    // Set current day as default
    _setCurrentDay();
    loadTasks();
    loadTopGoal();
    startTaskMonitoring();

    // Listen to quarter/year changes from dashboard
    final dashboardController = Get.find<DashboardController>();
    ever(dashboardController.currentQuarter, (_) => loadTasks());
    ever(dashboardController.currentQuarter, (_) => loadTopGoal());
    ever(dashboardController.currentYear, (_) => loadTasks());
    ever(dashboardController.currentYear, (_) => loadTopGoal());

    // Add listener to save top goal as user types
    topGoalController.addListener(() {
      saveTopGoalForSelectedDay();
    });
  }

  void _setCurrentDay() {
    final now = DateTime.now();
    final currentDay = _getDayString(now.weekday);
    selectedDay.value = currentDay;
  }

  void loadTasks() {
    final dashboardController = Get.find<DashboardController>();
    final currentQuarter = dashboardController.currentQuarter.value;
    final currentYear = dashboardController.currentYear.value;

    // Load tasks for current quarter and year
    final tasksData = storage.read<List>(
      'execution_tasks_${currentQuarter}_${currentYear}',
    );
    if (tasksData != null) {
      tasks.value = tasksData.map((t) => ExecutionTask.fromJson(t)).toList();
    } else {
      // Fallback to old format if quarter-specific data doesn't exist
      final fallbackData = storage.read<List>('execution_tasks');
      if (fallbackData != null) {
        tasks.value = fallbackData
            .map((t) => ExecutionTask.fromJson(t))
            .toList();
      }
    }
  }

  void loadTopGoal() {
    final dashboardController = Get.find<DashboardController>();
    final currentQuarter = dashboardController.currentQuarter.value;
    final currentYear = dashboardController.currentYear.value;

    // Load top goals for current quarter and year
    final goalsData = storage.read<Map>(
      'top_goals_per_day_${currentQuarter}_${currentYear}',
    );
    if (goalsData != null) {
      topGoalsPerDay.value = Map<String, String>.from(goalsData);
    } else {
      // Fallback to old format if quarter-specific data doesn't exist
      final fallbackData = storage.read<Map>('top_goals_per_day');
      if (fallbackData != null) {
        topGoalsPerDay.value = Map<String, String>.from(fallbackData);
      }
    }
    // Load the current day's goal
    loadTopGoalForSelectedDay();
  }

  void loadTopGoalForSelectedDay() {
    final currentGoal = topGoalsPerDay[selectedDay.value] ?? '';
    topGoalController.text = currentGoal;
  }

  void saveTopGoalForSelectedDay() {
    topGoalsPerDay[selectedDay.value] = topGoalController.text;
    saveTopGoals();
  }

  void selectDay(String day) {
    // Save current day's goal before switching
    saveTopGoalForSelectedDay();
    selectedDay.value = day;
    // Load the new day's goal
    loadTopGoalForSelectedDay();
  }

  List<ExecutionTask> getTasksForSelectedDay() {
    return tasks.where((task) => task.day == selectedDay.value).toList();
  }

  void addTask(String day, int hour, String taskType, String? specificTask) {
    final task = ExecutionTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      day: day,
      startHour: hour,
      taskType: taskType,
      specificTask: specificTask,
    );

    tasks.add(task);
    saveTasks();
  }

  void updateTask(String taskId, String taskType, String? specificTask) {
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      tasks[taskIndex].taskType = taskType;
      tasks[taskIndex].specificTask = specificTask;
      tasks.refresh();
      saveTasks();
    }
  }

  void toggleTaskCompletion(String taskId) {
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = tasks[taskIndex];

      if (!task.isCompleted) {
        // Task is being started - activate strict mode if it's deep work
        _activateStrictModeIfNeeded(task);
      } else {
        // Task is being completed - deactivate strict mode
        _deactivateStrictModeIfNeeded();
      }

      task.isCompleted = !task.isCompleted;
      task.completedAt = task.isCompleted ? DateTime.now() : null;
      tasks.refresh();
      saveTasks();
    }
  }

  void _activateStrictModeIfNeeded(dynamic task) {
    try {
      final settingsController = Get.find<SettingsController>();
      if (settingsController.strictModeEnabled.value &&
          task.taskType.toLowerCase().contains('deep work')) {
        final strictModeService = Get.find<StrictModeService>();
        strictModeService.activateStrictMode(task.taskType);
      }
    } catch (e) {
      print('Error activating strict mode: $e');
    }
  }

  void _deactivateStrictModeIfNeeded() {
    try {
      final strictModeService = Get.find<StrictModeService>();
      strictModeService.deactivateStrictMode();
    } catch (e) {
      print('Error deactivating strict mode: $e');
    }
  }

  void saveTasks() {
    final dashboardController = Get.find<DashboardController>();
    final currentQuarter = dashboardController.currentQuarter.value;
    final currentYear = dashboardController.currentYear.value;

    // Save tasks for current quarter and year
    storage.write(
      'execution_tasks_${currentQuarter}_${currentYear}',
      tasks.map((t) => t.toJson()).toList(),
    );
  }

  void saveTopGoals() {
    final dashboardController = Get.find<DashboardController>();
    final currentQuarter = dashboardController.currentQuarter.value;
    final currentYear = dashboardController.currentYear.value;

    // Save top goals for current quarter and year
    storage.write(
      'top_goals_per_day_${currentQuarter}_${currentYear}',
      topGoalsPerDay,
    );
  }

  void startTaskMonitoring() {
    // Check every minute for task reminders
    Future.delayed(Duration(minutes: 1), () {
      checkForDueTasks();
      startTaskMonitoring();
    });
  }

  void checkForDueTasks() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentDay = _getDayString(now.weekday);

    final dueTasks = tasks
        .where(
          (task) =>
              task.day == currentDay &&
              task.startHour == currentHour &&
              !task.isCompleted &&
              task.hasReminder,
        )
        .toList();

    if (dueTasks.isNotEmpty) {
      _showTaskReminderScreen(dueTasks.first);
    }
  }

  String _getDayString(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  void _showTaskReminderScreen(ExecutionTask task) {
    Get.to(
      () => TaskReminderScreen(task: task),
      fullscreenDialog: true,
      preventDuplicates: true,
    );
  }

  @override
  void onClose() {
    topGoalController.dispose();
    super.onClose();
  }
}
