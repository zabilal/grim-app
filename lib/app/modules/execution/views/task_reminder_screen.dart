import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grim_app/app/data/models/execution_task.dart';
import 'package:grim_app/app/services/strict_mode_service.dart';

class TaskReminderScreen extends GetView<StrictModeService> {
  final ExecutionTask task;

  const TaskReminderScreen({super.key, required this.task});

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Activate strict mode navigation blocking when widget is built
    if (task.isActive) {
      controller.activateStrictMode('deep work');
    }

    return Obx(
      () => PopScope(
        canPop: !(controller.isNavigationBlocked && task.isActive),
        onPopInvoked: (didPop) {
          // Deactivate strict mode when popping
          if (didPop && task.isActive) {
            controller.deactivateStrictMode();
          }
        },
        child: WillPopScope(
          onWillPop: () async {
            // Deactivate strict mode when trying to pop
            if (task.isActive) {
              controller.deactivateStrictMode();
            }
            return true;
          },
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
                      SizedBox(height: 24),
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
                          color: Colors.white.withOpacity(0.1),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
