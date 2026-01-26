import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grim_app/app/data/models/goal.dart';
import 'package:grim_app/app/modules/dashboard/controllers/dashboard_controller.dart';

class GoalsController extends GetxController {
  final storage = GetStorage();
  final goals = <Goal>[].obs;
  final filteredGoals = <Goal>[].obs;
  final isProfessionalGoal = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadGoals();

    // Listen to quarter/year changes from dashboard
    final dashboardController = Get.find<DashboardController>();
    ever(dashboardController.currentQuarter, (_) => loadGoals());
    ever(dashboardController.currentYear, (_) => loadGoals());
  }

  void loadGoals() {
    final dashboardController = Get.find<DashboardController>();
    final currentQuarter = dashboardController.currentQuarter.value;
    final currentYear = dashboardController.currentYear.value;

    // Load goals for current quarter and year
    final goalsData = storage.read<List>(
      'goals_${currentQuarter}_${currentYear}',
    );
    if (goalsData != null) {
      goals.value = goalsData.map((g) => Goal.fromJson(g)).toList();
      filteredGoals.value = goals;
    } else {
      // Fallback to old format if quarter-specific data doesn't exist
      final fallbackData = storage.read<List>('goals');
      if (fallbackData != null) {
        goals.value = fallbackData.map((g) => Goal.fromJson(g)).toList();
        filteredGoals.value = goals;
      }
    }
  }

  void createGoal(String title, String description, bool isProfessional) {
    final goal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 84)), // 12 weeks
      isProfessional: isProfessional,
    );

    goals.add(goal);
    saveGoals(); // Saves to quarter-specific storage key
    filteredGoals.value = goals;
  }

  void deleteGoal(String id) {
    goals.removeWhere((goal) => goal.id == id);
    saveGoals();
    filteredGoals.value = goals;
  }

  void toggleMilestone(String goalId, String milestoneId) {
    final goalIndex = goals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      final milestoneIndex = goals[goalIndex].milestones.indexWhere(
        (m) => m.id == milestoneId,
      );
      if (milestoneIndex != -1) {
        goals[goalIndex].milestones[milestoneIndex].isCompleted =
            !goals[goalIndex].milestones[milestoneIndex].isCompleted;

        // Update goal progress
        final completed = goals[goalIndex].milestones
            .where((m) => m.isCompleted)
            .length;
        goals[goalIndex].progress =
            completed / goals[goalIndex].milestones.length;

        goals.refresh();
        saveGoals();
      }
    }
  }

  void filterGoals(String filter) {
    if (filter == 'all') {
      filteredGoals.value = goals;
    } else if (filter == 'professional') {
      filteredGoals.value = goals.where((g) => g.isProfessional).toList();
    } else {
      filteredGoals.value = goals.where((g) => !g.isProfessional).toList();
    }
  }

  void saveGoals() {
    final dashboardController = Get.find<DashboardController>();
    final currentQuarter = dashboardController.currentQuarter.value;
    final currentYear = dashboardController.currentYear.value;

    // Save goals for current quarter and year
    final goalsData = goals.map((g) => g.toJson()).toList();
    storage.write('goals_${currentQuarter}_${currentYear}', goalsData);
  }
}
