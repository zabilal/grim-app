import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grim_app/app/data/models/goal.dart';
import 'package:grim_app/app/modules/goals/controllers/goals_controller.dart';
import 'package:grim_app/app/utils/theme_controller.dart';

class GoalsView extends GetView<GoalsController> {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('GOALS'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.goals.isEmpty) {
          return _buildEmptyState(themeController);
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.goals.length,
          itemBuilder: (context, index) {
            return _buildGoalCard(
              controller.goals[index],
              controller,
              themeController,
            );
          },
        );
      }),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: () => _showAddGoalDialog(controller),
          icon: Icon(Icons.add),
          label: Text('NEW GOAL'),
          backgroundColor: themeController.isDarkMode.value
              ? Colors.white
              : Colors.black,
          foregroundColor: themeController.isDarkMode.value
              ? Colors.black
              : Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeController themeController) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag, size: 80, color: Colors.grey[400]),
          SizedBox(height: 24),
          Text(
            'No Goals Yet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Create your first 12-week goal\nto start your execution journey',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    Goal goal,
    GoalsController controller,
    ThemeController themeController,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: goal.isProfessional ? Colors.blue : Colors.purple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.isProfessional ? 'PROFESSIONAL' : 'PERSONAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      controller.deleteGoal(goal.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              goal.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(goal.description, style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  '${_formatDate(goal.startDate)} - ${_formatDate(goal.endDate)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: Colors.grey[300],
              minHeight: 8,
            ),
            SizedBox(height: 8),
            Text(
              '${(goal.progress * 100).toStringAsFixed(0)}% Complete',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            if (goal.milestones.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Milestones (${goal.milestones.where((m) => m.isCompleted).length}/${goal.milestones.length})',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...goal.milestones
                  .take(3)
                  .map(
                    (milestone) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(milestone.title),
                      value: milestone.isCompleted,
                      onChanged: (value) {
                        controller.toggleMilestone(goal.id, milestone.id);
                      },
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showFilterDialog(GoalsController controller) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Goals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text('All Goals'),
              onTap: () {
                controller.filterGoals('all');
                Get.back();
              },
            ),
            ListTile(
              title: Text('Professional'),
              onTap: () {
                controller.filterGoals('professional');
                Get.back();
              },
            ),
            ListTile(
              title: Text('Personal'),
              onTap: () {
                controller.filterGoals('personal');
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(GoalsController controller) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final themeController = Get.find<ThemeController>();

    // Reset the goal type when dialog opens
    controller.isProfessionalGoal.value = true;

    Get.dialog(
      AlertDialog(
        title: Text('Create New Goal'),
        content: Obx(
          () => Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeController.isDarkMode.value
                  ? Colors.grey[800]
                  : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Goal Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Goal Type:', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(
                            () => ChoiceChip(
                              label: Text('Professional'),
                              selected: controller.isProfessionalGoal.value,
                              onSelected: (selected) {
                                controller.isProfessionalGoal.value = true;
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Obx(
                            () => ChoiceChip(
                              label: Text('Personal'),
                              selected: !controller.isProfessionalGoal.value,
                              onSelected: (selected) {
                                controller.isProfessionalGoal.value = false;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                controller.createGoal(
                  titleController.text,
                  descController.text,
                  controller.isProfessionalGoal.value,
                );
                Get.back();
              }
            },
            child: Text('CREATE'),
          ),
        ],
      ),
    );
  }
}
