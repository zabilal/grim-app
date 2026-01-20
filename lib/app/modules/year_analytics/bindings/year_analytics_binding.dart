import 'package:get/get.dart';
import 'package:grim_app/app/modules/year_analytics/controllers/year_analytics_controller.dart';

class YearAnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => YearAnalyticsController());
  }
}
