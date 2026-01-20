import 'package:get/get.dart';

import '../controllers/execution_controller.dart';

class ExecutionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExecutionController>(
      () => ExecutionController(),
    );
  }
}
