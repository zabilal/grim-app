import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grim_app/app/modules/settings/controllers/settings_controller.dart';
import 'package:grim_app/app/utils/theme_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Text('SETTINGS'), centerTitle: true),
      body: ListView(
        children: [
          _buildSection('APPEARANCE', [
            Obx(
              () => SwitchListTile(
                secondary: Icon(
                  themeController.isDarkMode.value
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                title: Text('Dark Mode'),
                value: themeController.isDarkMode.value,
                onChanged: (value) => themeController.toggleTheme(),
              ),
            ),
          ]),
          _buildSection('NOTIFICATIONS', [
            Obx(
              () => SwitchListTile(
                secondary: Icon(Icons.notifications),
                title: Text('Task Reminders'),
                subtitle: Text('Get notified when tasks are due'),
                value: controller.notificationsEnabled.value,
                onChanged: (value) {
                  controller.toggleNotifications();
                },
              ),
            ),
            Obx(
              () => SwitchListTile(
                secondary: Icon(Icons.block),
                title: Text('Strict Mode'),
                subtitle: Text('Block apps during Deep Work sessions'),
                value: controller.strictModeEnabled.value,
                onChanged: (value) {
                  controller.toggleStrictMode();
                },
              ),
            ),
          ]),
          _buildSection('EXECUTION SHEET', [
            ListTile(
              leading: Icon(Icons.access_time),
              title: Text('Deep Work Hours'),
              subtitle: Obx(
                () => Text('${controller.deepWorkHours.value} hours per day'),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showDeepWorkHoursDialog(controller),
            ),
            Obx(
              () => SwitchListTile(
                secondary: Icon(Icons.apps),
                title: Text('Block Social Media'),
                subtitle: Text('During Deep Work periods'),
                value: controller.blockSocialMedia.value,
                onChanged: (value) {
                  controller.toggleBlockSocialMedia();
                },
              ),
            ),
          ]),
          _buildSection('DATA', [
            ListTile(
              leading: Icon(Icons.download),
              title: Text('Export Data'),
              subtitle: Text('Download all your data'),
              onTap: () {
                Get.snackbar('Export', 'Data export feature coming soon');
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: Text(
                'Clear All Data',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: Text('This cannot be undone'),
              onTap: () => _showClearDataDialog(),
            ),
          ]),
          _buildSection('ABOUT', [
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Version'),
              subtitle: Text('1.0.0'),
            ),
            ListTile(
              leading: Icon(Icons.description),
              title: Text('Privacy Policy'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.gavel),
              title: Text('Terms of Service'),
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) {
      return 'U';
    }
    return name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  void _showDeepWorkHoursDialog(SettingsController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('Deep Work Hours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How many hours of deep work per day?'),
            SizedBox(height: 20),
            Obx(
              () => Slider(
                value: controller.deepWorkHours.value.toDouble(),
                min: 2,
                max: 8,
                divisions: 6,
                label: '${controller.deepWorkHours.value} hours',
                onChanged: (value) {
                  controller.setDeepWorkHours(value.toInt());
                },
              ),
            ),
            Obx(
              () => Text(
                '${controller.deepWorkHours.value} hours',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('CLOSE')),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Clear All Data?'),
        content: Text(
          'This will permanently delete all your goals, tasks, and progress. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Cleared',
                'All data has been deleted',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }
}
