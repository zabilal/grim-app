import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grim_app/app/modules/execution/controllers/execution_controller.dart';
import 'package:grim_app/app/utils/theme_controller.dart';

class ExecutionSheetView extends GetView<ExecutionController> {
  const ExecutionSheetView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('TIME BOXING'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddTaskDialog(controller),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildGoalHeader(controller, themeController),
          _buildDayTabs(controller, themeController),
          Expanded(
            child: Obx(() => _buildDaySchedule(controller, themeController)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalHeader(
    ExecutionController controller,
    ThemeController themeController,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      color: themeController.isDarkMode.value
          ? Colors.grey[800]
          : Colors.grey[100],
      child: Column(
        children: [
          TextField(
            controller: controller.topGoalController,
            decoration: InputDecoration(
              labelText: 'TOP GOAL OF TODAY',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: themeController.isDarkMode.value
                  ? Colors.grey[700]
                  : Colors.white,
            ),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs(
    ExecutionController controller,
    ThemeController themeController,
  ) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    return SizedBox(
      height: 50,
      child: Obx(() {
        final selectedDay = controller.selectedDay.value;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final isSelected = selectedDay == day;

            return GestureDetector(
              onTap: () => controller.selectDay(day),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                padding: EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (themeController.isDarkMode.value
                            ? Colors.white
                            : Colors.black)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (themeController.isDarkMode.value
                              ? Colors.white
                              : Colors.black)
                        : Colors.grey,
                  ),
                ),
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: isSelected
                          ? (themeController.isDarkMode.value
                                ? Colors.black
                                : Colors.white)
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildDaySchedule(
    ExecutionController controller,
    ThemeController themeController,
  ) {
    final tasks = controller.getTasksForSelectedDay();

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 10, // 8 AM to 5 PM = 10 hours
      itemBuilder: (context, index) {
        final hour = 8 + index;
        final task = tasks.firstWhereOrNull((t) => t.startHour == hour);

        return _buildTimeSlot(hour, task, controller, themeController);
      },
    );
  }

  Widget _buildTimeSlot(
    int hour,
    task,
    ExecutionController controller,
    ThemeController themeController,
  ) {
    final timeString = '${hour.toString().padLeft(2, '0')}:00';
    final isDeepWork = task?.taskType == 'Deep Work';
    final isBreak = task?.taskType == 'Eat' || task?.taskType == 'Walk';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDeepWork
              ? Colors.blue
              : isBreak
              ? Colors.orange
              : (themeController.isDarkMode.value
                    ? Colors.grey[600]!
                    : Colors.grey[300]!),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: task?.isCompleted ?? false
            ? Colors.green[50]
            : (themeController.isDarkMode.value
                  ? Colors.grey[800]
                  : Colors.white),
      ),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          child: Text(
            timeString,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          task?.taskType ?? 'Free Time',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task?.isCompleted ?? false
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: task?.specificTask != null ? Text(task!.specificTask!) : null,
        trailing: task != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) {
                      controller.toggleTaskCompletion(task.id);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditTaskDialog(controller, task),
                  ),
                ],
              )
            : IconButton(
                icon: Icon(Icons.add_circle_outline),
                onPressed: () => _showAddTaskDialog(controller, hour: hour),
              ),
      ),
    );
  }

  void _showAddTaskDialog(ExecutionController controller, {int? hour}) {
    final taskTypes = [
      'Deep Work',
      'Plan Day',
      'Meetings',
      'Workout',
      'To Do List',
      'Eat',
      'Walk',
      'Emails',
      'Messenger',
    ];

    String selectedType = taskTypes[0];
    final descController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: InputDecoration(
                labelText: 'Task Type',
                border: OutlineInputBorder(),
              ),
              items: taskTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => selectedType = value!,
            ),
            SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Specific Task (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              controller.addTask(
                controller.selectedDay.value,
                hour ?? 8,
                selectedType,
                descController.text.isEmpty ? null : descController.text,
              );
              Get.back();
            },
            child: Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(ExecutionController controller, task) {
    final taskTypes = [
      'Deep Work',
      'Plan Day',
      'Meetings',
      'Workout',
      'To Do List',
      'Eat',
      'Walk',
      'Emails',
      'Messenger',
    ];

    String selectedType = task.taskType;
    final descController = TextEditingController(text: task.specificTask ?? '');

    Get.dialog(
      AlertDialog(
        title: Text('Edit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: InputDecoration(
                labelText: 'Task Type',
                border: OutlineInputBorder(),
              ),
              items: taskTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => selectedType = value!,
            ),
            SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Specific Task (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              controller.updateTask(
                task.id,
                selectedType,
                descController.text.isEmpty ? null : descController.text,
              );
              Get.back();
            },
            child: Text('UPDATE'),
          ),
        ],
      ),
    );
  }
}
