import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grim_app/app/data/models/execution_task.dart';
import 'package:grim_app/app/modules/execution/controllers/execution_controller.dart';
import 'package:grim_app/app/services/notification_service.dart';

class TaskReminderScreen extends StatelessWidget {
  final ExecutionTask task;

  const TaskReminderScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {}, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm, size: 120, color: Colors.red),
                  SizedBox(height: 40),
                  Text(
                    'TIME TO EXECUTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          task.taskType.toUpperCase(),
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (task.specificTask != null) ...[
                          SizedBox(height: 16),
                          Text(
                            task.specificTask!,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    'No distractions. No excuses.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete this task to continue.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final controller = Get.find<ExecutionController>();
                        controller.toggleTaskCompletion(task.id);
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'TASK COMPLETED',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // TextButton(
                  //   onPressed: () {
                  //     // Snooze for 5 minutes using notification service
                  //     final notificationService =
                  //         Get.find<NotificationService>();
                  //     final snoozeTime = DateTime.now().add(
                  //       const Duration(minutes: 5),
                  //     );
                  //     notificationService.scheduleTaskReminder(
                  //       task,
                  //       snoozeTime,
                  //     );

                  //     Get.back();
                  //     Get.snackbar(
                  //       'Snoozed',
                  //       'Reminder will appear in 5 minutes',
                  //       backgroundColor: Colors.orange,
                  //       colorText: Colors.white,
                  //     );
                  //   },
                  //   child: Text(
                  //     'Snooze (5 min)',
                  //     style: TextStyle(color: Colors.white54),
                  //   ),
                  // ),
                
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
