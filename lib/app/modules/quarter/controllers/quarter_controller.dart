import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grim_app/app/modules/dashboard/controllers/dashboard_controller.dart';

class QuarterController extends GetxController {
  final storage = GetStorage();
  final selectedQuarter = 1.obs;
  final selectedYear = DateTime.now().year.obs;
  final availableYears = <int>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAvailableYears();
    loadCurrentSelection();
  }

  void loadAvailableYears() {
    // Load years from storage or generate from current year
    final storedYears = storage.read<List>('available_years');
    if (storedYears != null) {
      availableYears.value = storedYears.cast<int>();
    } else {
      // Generate years from current year - 2 to current year + 2
      final currentYear = DateTime.now().year;
      availableYears.value = List.generate(
        5,
        (index) => currentYear - 2 + index,
      );
      saveAvailableYears();
    }
  }

  void loadCurrentSelection() {
    final dashboardController = Get.find<DashboardController>();
    selectedQuarter.value = dashboardController.currentQuarter.value;
    selectedYear.value = dashboardController.currentYear.value;
  }

  void saveAvailableYears() {
    storage.write('available_years', availableYears);
  }

  void selectQuarter(int quarter) {
    selectedQuarter.value = quarter;
  }

  void selectYear(int year) {
    selectedYear.value = year;
  }

  void applySelection() {
    final dashboardController = Get.find<DashboardController>();
    dashboardController.navigateToQuarter(selectedQuarter.value);
    dashboardController.navigateToYear(selectedYear.value);
    Get.back();
  }

  List<String> getQuarterNames() {
    return ['Q1', 'Q2', 'Q3', 'Q4'];
  }

  String getQuarterDescription(int quarter) {
    switch (quarter) {
      case 1:
        return 'Jan - Mar';
      case 2:
        return 'Apr - Jun';
      case 3:
        return 'Jul - Sep';
      case 4:
        return 'Oct - Dec';
      default:
        return '';
    }
  }
}
