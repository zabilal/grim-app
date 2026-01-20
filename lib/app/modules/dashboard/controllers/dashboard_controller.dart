import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grim_app/app/data/models/goal.dart';
import 'package:grim_app/app/modules/goals/controllers/goals_controller.dart';
import 'package:grim_app/app/modules/execution/controllers/execution_controller.dart';

class DashboardController extends GetxController {
  final storage = GetStorage();
  final goals = <Goal>[].obs;
  final currentWeek = 1.obs;
  final currentQuarter = 1.obs;
  final currentYear = DateTime.now().year.obs;
  final totalWeeks = 12.obs;
  final completedTasks = 0.obs;
  final totalTasks = 0.obs;
  final weeklyProgress = 0.0.obs;
  final todayTopGoal = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadQuarterSettings();
    loadGoals();
    loadTodayTopGoal();
    calculateProgress();

    // Setup reactive listeners for quarter/year changes
    ever(currentQuarter, (_) => _refreshOtherControllers());
    ever(currentYear, (_) => _refreshOtherControllers());
  }

  void loadQuarterSettings() {
    currentQuarter.value = storage.read('current_quarter') ?? 1;
    currentYear.value = storage.read('current_year') ?? DateTime.now().year;
    // Calculate current week based on quarter
    currentWeek.value = storage.read('current_week') ?? 1;
  }

  void saveQuarterSettings() {
    storage.write('current_quarter', currentQuarter.value);
    storage.write('current_year', currentYear.value);
    storage.write('current_week', currentWeek.value);
  }

  void navigateToQuarter(int quarter) {
    currentQuarter.value = quarter;
    currentWeek.value = 1; // Reset to first week of quarter
    saveQuarterSettings();
    loadGoals();
    calculateProgress();

    // Refresh other controllers to load quarter-specific data
    _refreshOtherControllers();
  }

  void navigateToYear(int year) {
    currentYear.value = year;
    currentQuarter.value = 1; // Reset to first quarter
    currentWeek.value = 1; // Reset to first week
    saveQuarterSettings();
    loadGoals();
    calculateProgress();

    // Refresh other controllers to load quarter-specific data
    _refreshOtherControllers();
  }

  void _refreshOtherControllers() {
    try {
      // Dispose old controllers if they exist
      if (Get.isRegistered<GoalsController>()) {
        Get.delete<GoalsController>();
      }
      if (Get.isRegistered<ExecutionController>()) {
        Get.delete<ExecutionController>();
      }

      // Recreate controllers with fresh state
      Get.put(GoalsController());
      Get.put(ExecutionController());

      // Wait a moment for controllers to initialize
      Future.delayed(Duration(milliseconds: 100), () {
        try {
          // Refresh the new controllers
          final goalsController = Get.find<GoalsController>();
          goalsController.loadGoals();

          final executionController = Get.find<ExecutionController>();
          executionController.loadTasks();
          executionController.loadTopGoal();
        } catch (e) {
          print('Error refreshing controllers after delay: $e');
        }
      });
    } catch (e) {
      // Controllers might not be initialized yet
      print('Error refreshing controllers: $e');
    }
  }

  String getQuarterDisplay() {
    return 'Q${currentQuarter.value} ${currentYear.value}';
  }

  void loadGoals() {
    final goalsData = storage.read<List>('goals');
    if (goalsData != null) {
      goals.value = goalsData.map((g) => Goal.fromJson(g)).toList();
    }
  }

  void loadTodayTopGoal() {
    final goalsData = storage.read<Map>('top_goals_per_day');
    if (goalsData != null) {
      final topGoalsPerDay = Map<String, String>.from(goalsData);
      final currentDay = _getCurrentDayString();
      todayTopGoal.value = topGoalsPerDay[currentDay] ?? '';
    }
  }

  String _getCurrentDayString() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return days[now.weekday - 1];
  }

  void calculateProgress() {
    // Load goals for current quarter and year for accurate calculations
    final currentQuarterGoals = _loadQuarterGoals();
    goals.value = currentQuarterGoals;

    if (currentQuarterGoals.isEmpty) {
      weeklyProgress.value = 0.0;
      completedTasks.value = 0;
      totalTasks.value = 0;
      return;
    }

    double totalProgress = currentQuarterGoals.fold(
      0.0,
      (sum, goal) => sum + goal.progress,
    );
    weeklyProgress.value = totalProgress / currentQuarterGoals.length;

    // Calculate completed vs total tasks for current quarter
    int completed = 0;
    int total = 0;
    for (var goal in currentQuarterGoals) {
      for (var milestone in goal.milestones) {
        total++;
        if (milestone.isCompleted) completed++;
      }
    }
    completedTasks.value = completed;
    totalTasks.value = total;
  }

  List<Goal> _loadQuarterGoals() {
    // Load goals for current quarter and year
    final goalsData = storage.read<List>(
      'goals_${currentQuarter.value}_${currentYear.value}',
    );
    if (goalsData != null) {
      return goalsData.map((g) => Goal.fromJson(g)).toList();
    } else {
      // Fallback to old format if quarter-specific data doesn't exist
      final fallbackData = storage.read<List>('goals');
      if (fallbackData != null) {
        return fallbackData.map((g) => Goal.fromJson(g)).toList();
      }
    }
    return [];
  }

  void addGoal(Goal goal) {
    goals.add(goal);
    saveGoals();
    calculateProgress();
  }

  void saveGoals() {
    // Save goals for current quarter and year
    storage.write(
      'goals_${currentQuarter.value}_${currentYear.value}',
      goals.map((g) => g.toJson()).toList(),
    );
  }
}
