import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final storage = GetStorage();

  final notificationsEnabled = true.obs;
  final strictModeEnabled = true.obs;
  final blockSocialMedia = true.obs;
  final deepWorkHours = 4.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  void loadSettings() {
    notificationsEnabled.value = storage.read('notifications') ?? true;
    strictModeEnabled.value = storage.read('strictMode') ?? true;
    blockSocialMedia.value = storage.read('blockSocial') ?? true;
    deepWorkHours.value = storage.read('deepWorkHours') ?? 4;
  }

  void toggleNotifications() {
    notificationsEnabled.value = !notificationsEnabled.value;
    storage.write('notifications', notificationsEnabled.value);
  }

  void toggleStrictMode() {
    strictModeEnabled.value = !strictModeEnabled.value;
    storage.write('strictMode', strictModeEnabled.value);
  }

  void toggleBlockSocialMedia() {
    blockSocialMedia.value = !blockSocialMedia.value;
    storage.write('blockSocial', blockSocialMedia.value);
  }

  void setDeepWorkHours(int hours) {
    deepWorkHours.value = hours;
    storage.write('deepWorkHours', hours);
  }
}
