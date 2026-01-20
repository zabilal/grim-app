import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grim_app/app/modules/quarter/controllers/quarter_controller.dart';
import 'package:grim_app/app/utils/theme_controller.dart';

class QuarterView extends GetView<QuarterController> {
  const QuarterView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Text('SELECT QUARTER'), centerTitle: true),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YEAR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeController.isDarkMode.value
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            SizedBox(height: 16),
            _buildYearSelector(themeController),
            SizedBox(height: 32),
            Text(
              'QUARTER',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeController.isDarkMode.value
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            SizedBox(height: 16),
            _buildQuarterSelector(themeController),
            Spacer(),
            _buildApplyButton(themeController),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector(ThemeController themeController) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
            color: themeController.isDarkMode.value
                ? Colors.grey[600]!
                : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.availableYears.map((year) {
            final isSelected = year == controller.selectedYear.value;
            return ChoiceChip(
              label: Text(year.toString()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) controller.selectYear(year);
              },
              backgroundColor: isSelected
                  ? (themeController.isDarkMode.value
                        ? Colors.white
                        : Colors.black)
                  : Colors.transparent,
              labelStyle: TextStyle(
                color: isSelected
                    ? (themeController.isDarkMode.value
                          ? Colors.black
                          : Colors.white)
                    : (themeController.isDarkMode.value
                          ? Colors.white
                          : Colors.black),
              ),
              side: BorderSide(
                color: themeController.isDarkMode.value
                    ? Colors.grey[600]!
                    : Colors.grey[300]!,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuarterSelector(ThemeController themeController) {
    return Obx(
      () => Column(
        children: [
          ...List.generate(4, (index) {
            final quarter = index + 1;
            final isSelected = quarter == controller.selectedQuarter.value;
            final description = controller.getQuarterDescription(quarter);

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => controller.selectQuarter(quarter),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (themeController.isDarkMode.value
                              ? Colors.white
                              : Colors.black)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeController.isDarkMode.value
                          ? Colors.grey[600]!
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Q$quarter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? (themeController.isDarkMode.value
                                  ? Colors.black
                                  : Colors.white)
                            : (themeController.isDarkMode.value
                                  ? Colors.white
                                  : Colors.black),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'Quarter $quarter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeController.isDarkMode.value
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                subtitle: Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: Colors.green, size: 24)
                    : null,
                tileColor: isSelected
                    ? (themeController.isDarkMode.value
                          ? Colors.grey[800]?.withOpacity(0.5)
                          : Colors.grey[100])
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? (themeController.isDarkMode.value
                              ? Colors.white
                              : Colors.black)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildApplyButton(ThemeController themeController) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: controller.applySelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: themeController.isDarkMode.value
                ? Colors.white
                : Colors.black,
            foregroundColor: themeController.isDarkMode.value
                ? Colors.black
                : Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'APPLY SELECTION',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
