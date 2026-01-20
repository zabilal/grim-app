import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grim_app/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:grim_app/app/routes/app_pages.dart';
import 'package:grim_app/app/utils/theme_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.getQuarterDisplay())),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.analytics_outlined),
            onPressed: () => Get.toNamed(Routes.yearAnalytics),
            tooltip: 'Year Analytics',
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => Get.toNamed(Routes.quarter),
            tooltip: 'Quarter Selection',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Get.toNamed(Routes.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.loadGoals();
          controller.calculateProgress();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildMotivationalQuote(),
              SizedBox(height: 24),
              _buildWeekProgress(),
              SizedBox(height: 24),
              _buildStatsGrid(),
              SizedBox(height: 24),
              _buildGoalsList(),
              SizedBox(height: 24),
              // _buildQuickActions(),
            ],
          ),
        ),
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: () => Get.toNamed('/execution'),
          icon: Icon(Icons.today),
          label: Text('TODAY\'S EXECUTION'),
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

  Widget _buildMotivationalQuote() {
    return Obx(() {
      final hasTopGoal = controller.todayTopGoal.value.isNotEmpty;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a1a1a), Color(0xFF2d2d2d)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GRIM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'HONOR WILL COME',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 16),
            Obx(
              () => Text(
                'Week ${controller.currentWeek.value} of ${controller.totalWeeks.value}',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            if (hasTopGoal) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'TODAY\'S TOP GOAL',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.fitness_center,
                          color: Colors.red.withOpacity(0.7),
                          size: 16,
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        controller.todayTopGoal.value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Get.toNamed('/execution'),
                            icon: Icon(
                              Icons.edit,
                              color: Color(0xFF1a1a1a),
                              size: 14,
                            ),
                            label: Text(
                              'EXECUTE',
                              style: TextStyle(color: Color(0xFF1a1a1a)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Color(0xFF1a1a1a),
                              padding: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'CHALLENGE',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildWeekProgress() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WEEKLY PROGRESS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 16),
            Obx(
              () => Column(
                children: [
                  LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(12),
                    value: controller.weeklyProgress.value,
                    minHeight: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      controller.weeklyProgress.value > 0.7
                          ? Colors.green
                          : controller.weeklyProgress.value > 0.4
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(controller.weeklyProgress.value * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${controller.completedTasks.value}/${controller.totalTasks.value} tasks',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Obx(
      () => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            'Active Goals',
            '${controller.goals.length}',
            Icons.flag,
            Colors.blue,
          ),
          _buildStatCard(
            'Completion Rate',
            '${(controller.weeklyProgress.value * 100).toStringAsFixed(0)}%',
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatCard(
            'Current Week',
            '${controller.currentWeek.value}/12',
            Icons.calendar_today,
            Colors.orange,
          ),
          _buildStatCard(
            'Tasks Done',
            '${controller.completedTasks.value}',
            Icons.task_alt,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'YOUR GOALS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/goals'),
              child: Text('VIEW ALL'),
            ),
          ],
        ),
        SizedBox(height: 12),
        Obx(
          () => controller.goals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: controller.goals.length.clamp(0, 3),
                  itemBuilder: (context, index) {
                    final goal = controller.goals[index];
                    return _buildGoalCard(goal);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(goal) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: goal.isProfessional ? Colors.blue : Colors.purple,
          child: Icon(
            goal.isProfessional ? Icons.work : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(goal.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(height: 4),
            Text('${(goal.progress * 100).toStringAsFixed(0)}% Complete'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to goal details
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 10, bottom: 70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.flag, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No goals yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first 12-week goal',
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.toNamed('/goals'),
            child: Text('CREATE GOAL'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed('/goals'),
                icon: Icon(Icons.add),
                label: Text('New Goal'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Get.toNamed('/execution'),
                icon: Icon(Icons.today),
                label: Text('Execute'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
