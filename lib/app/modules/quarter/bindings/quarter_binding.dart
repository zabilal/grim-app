import 'package:get/get.dart';
import 'package:grim_app/app/modules/quarter/controllers/quarter_controller.dart';

class QuarterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QuarterController>(() => QuarterController());
  }
}
