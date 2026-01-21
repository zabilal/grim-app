import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grim_app/app/data/models/execution_task.dart';
import 'package:grim_app/app/modules/execution/controllers/execution_controller.dart';
import 'package:grim_app/app/services/strict_mode_service.dart';

class TaskReminderScreen extends StatelessWidget {
  final ExecutionTask task;

  const TaskReminderScreen({super.key, required this.task});

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final strictModeService = Get.find<StrictModeService>();

    return Obx(
      () => PopScope(
        canPop: !(strictModeService.isNavigationBlocked && task.isActive),
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
                      task.isActive ? 'TASK IN PROGRESS' : 'TIME TO EXECUTE',
                      style: TextStyle(
                        color: task.isActive ? Colors.orange : Colors.white,
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
                        border: Border.all(
                          color: task.isActive ? Colors.orange : Colors.red,
                          width: 2,
                        ),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (task.isActive && task.startedAt != null) ...[
                            SizedBox(height: 16),
                            Text(
                              'Started at ${_formatTime(task.startedAt!)}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          // Add countdown timer display
                          GetBuilder<ExecutionController>(
                            builder: (controller) {
                              if (controller.isTimerRunning.value &&
                                  controller.remainingTime.value > 0) {
                                return Column(
                                  children: [
                                    SizedBox(height: 16),
                                    Text(
                                      'TIME REMAINING',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      controller.getRemainingTimeString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return SizedBox.shrink();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    Text(
                      task.isActive
                          ? 'Stay focused. You\'re doing great!'
                          : 'No distractions. No excuses.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      task.isActive
                          ? 'The task will auto-complete when time ends.'
                          : 'Complete this task to continue.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 60),
                    // Show timer status instead of complete button
                    GetBuilder<ExecutionController>(
                      builder: (controller) {
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: controller.isTimerRunning.value
                                ? Colors.orange.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: controller.isTimerRunning.value
                                  ? Colors.orange
                                  : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                controller.isTimerRunning.value
                                    ? 'TASK IN PROGRESS'
                                    : 'TASK COMPLETED',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                              if (controller.isTimerRunning.value) ...[
                                SizedBox(height: 8),
                                Text(
                                  'Auto-completes when time ends',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
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
      ),
    );
  }
}
