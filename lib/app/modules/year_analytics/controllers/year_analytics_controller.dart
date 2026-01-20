import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grim_app/app/data/models/goal.dart';
import 'package:grim_app/app/utils/theme_controller.dart';

class YearAnalyticsController extends GetxController {
  final storage = GetStorage();
  final selectedYear = DateTime.now().year.obs;
  final quarterlyGoals = <int, List<Goal>>{}.obs; // quarter -> goals
  final quarterlyProgress = <int, double>{}.obs; // quarter -> progress
  final quarterlyTasks =
      <int, Map<String, int>>{}.obs; // quarter -> {completed, total}
  final yearlyProgress = 0.0.obs;
  final totalYearlyGoals = 0.obs;
  final completedYearlyGoals = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadYearlyData();
  }

  void loadYearlyData() {
    final year = selectedYear.value;
    double totalProgress = 0.0;
    int totalGoals = 0;
    int completedGoals = 0;

    // Load data for each quarter
    for (int quarter = 1; quarter <= 4; quarter++) {
      final quarterGoals = _loadQuarterGoals(quarter, year);
      quarterlyGoals[quarter] = quarterGoals;

      // Calculate quarter progress
      if (quarterGoals.isNotEmpty) {
        double quarterProgress =
            quarterGoals.fold(0.0, (sum, goal) => sum + goal.progress) /
            quarterGoals.length;
        quarterlyProgress[quarter] = quarterProgress;
        totalProgress += quarterProgress;

        // Count goals and tasks for this quarter
        totalGoals += quarterGoals.length;
        completedGoals += quarterGoals.where((g) => g.progress >= 1.0).length;

        quarterlyTasks[quarter] = {
          'completed': quarterGoals.fold(
            0,
            (sum, goal) =>
                sum + goal.milestones.where((m) => m.isCompleted).length,
          ),
          'total': quarterGoals.fold(
            0,
            (sum, goal) => sum + goal.milestones.length,
          ),
        };
      } else {
        quarterlyProgress[quarter] = 0.0;
        quarterlyTasks[quarter] = {'completed': 0, 'total': 0};
      }
    }

    // Calculate yearly totals
    yearlyProgress.value = totalGoals > 0 ? totalProgress / 4 : 0.0;
    totalYearlyGoals.value = totalGoals;
    completedYearlyGoals.value = completedGoals;
  }

  List<Goal> _loadQuarterGoals(int quarter, int year) {
    final goalsData = storage.read<List>('goals_${quarter}_${year}');
    if (goalsData != null) {
      return goalsData.map((g) => Goal.fromJson(g)).toList();
    }

    // Fallback to old format
    final fallbackData = storage.read<List>('goals');
    if (fallbackData != null) {
      return fallbackData.map((g) => Goal.fromJson(g)).toList();
    }

    return [];
  }

  void changeYear(int year) {
    selectedYear.value = year;
    loadYearlyData();
  }

  String getQuarterName(int quarter) {
    switch (quarter) {
      case 1:
        return 'Q1 (Jan-Mar)';
      case 2:
        return 'Q2 (Apr-Jun)';
      case 3:
        return 'Q3 (Jul-Sep)';
      case 4:
        return 'Q4 (Oct-Dec)';
      default:
        return 'Q$quarter';
    }
  }

  Color getQuarterColor(int quarter, ThemeController themeController) {
    final isDark = themeController.isDarkMode.value;
    switch (quarter) {
      case 1:
        return isDark ? Colors.blue.shade300 : Colors.blue.shade600;
      case 2:
        return isDark ? Colors.green.shade300 : Colors.green.shade600;
      case 3:
        return isDark ? Colors.orange.shade300 : Colors.orange.shade600;
      case 4:
        return isDark ? Colors.purple.shade300 : Colors.purple.shade600;
      default:
        return Colors.grey;
    }
  }
}
