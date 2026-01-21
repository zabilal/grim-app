import 'dart:async';
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

  // Timer variables for auto-close functionality
  final remainingTime = 0.obs;
  final isTimerRunning = false.obs;
  Timer? _timer;
  String? _activeTaskId;

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

      if (!task.isActive && !task.isCompleted) {
        // Task is being started - activate it
        task.isActive = true;
        task.startedAt = DateTime.now();
        _activateStrictModeIfNeeded(task);
      } else if (task.isActive && !task.isCompleted) {
        // Task is being completed
        task.isActive = false;
        task.isCompleted = true;
        task.completedAt = DateTime.now();
        _deactivateStrictModeIfNeeded();
      } else if (task.isCompleted) {
        // Task is being reset (uncompleted)
        task.isCompleted = false;
        task.completedAt = null;
        task.isActive = false;
        task.startedAt = null;
        _deactivateStrictModeIfNeeded();
      }

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
    // Automatically activate the task when showing the reminder
    if (!task.isActive && !task.isCompleted) {
      task.isActive = true;
      task.startedAt = DateTime.now();
      _activateStrictModeIfNeeded(task);
      saveTasks();
    }

    // Start auto-close timer (1 hour default duration)
    _startAutoCloseTimer(task);

    Get.to(
      () => TaskReminderScreen(task: task),
      fullscreenDialog: true,
      preventDuplicates: true,
    );
  }

  void _startAutoCloseTimer(ExecutionTask task) {
    _stopTimer(); // Stop any existing timer

    _activeTaskId = task.id;
    isTimerRunning.value = true;

    // Set default duration to 1 hour (60 minutes)
    final durationMinutes = 60;
    final endTime = task.startedAt!.add(Duration(minutes: durationMinutes));
    final now = DateTime.now();
    remainingTime.value = endTime.difference(now).inSeconds;

    if (remainingTime.value > 0) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        remainingTime.value--;
        if (remainingTime.value <= 0) {
          _stopTimer();
          _autoCompleteTask(task.id);
        }
      });
    } else {
      // Task should have already ended
      _stopTimer();
      _autoCompleteTask(task.id);
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    isTimerRunning.value = false;
    remainingTime.value = 0;
    _activeTaskId = null;
  }

  void _autoCompleteTask(String taskId) {
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = tasks[taskIndex];
      if (task.isActive && !task.isCompleted) {
        // Complete the task
        task.isActive = false;
        task.isCompleted = true;
        task.completedAt = DateTime.now();
        _deactivateStrictModeIfNeeded();
        tasks.refresh();
        saveTasks();

        // Close reminder screen if open
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        // Show completion notification
        Get.snackbar(
          'Task Completed',
          'Task time has ended and was marked as complete',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      }
    }
  }

  String getRemainingTimeString() {
    final seconds = remainingTime.value;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  void onClose() {
    _stopTimer();
    topGoalController.dispose();
    super.onClose();
  }
}
