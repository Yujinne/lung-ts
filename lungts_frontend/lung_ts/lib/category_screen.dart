import 'package:flutter/material.dart';
import 'package:lung_ts/report_screen.dart';
import 'diary_list_screen.dart';
import 'medicine_screen.dart';
import 'act_screen.dart';
import 'transition_helper.dart';
import 'package:lung_ts/app_colors.dart';

class CategoryScreen extends StatelessWidget {
  final String title;

  const CategoryScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> buttonData = [
      {"label": "일기장", "icon": Icons.book, "screen": const DiaryListScreen()},
      {"label": "약", "icon": Icons.medication, "screen": MedicineAlarmScreen()},
      {"label": "ACT", "icon": Icons.bar_chart, "screen": ActScreen()},
      {"label": "보고서", "icon": Icons.assignment, "screen": ReportScreen()},
      {"label": "커뮤니티", "icon": Icons.forum, "screen": null},
      {"label": "등록", "icon": Icons.add_box, "screen": null},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: buttonData.length,
          itemBuilder: (context, index) {
            final item = buttonData[index];
            return GestureDetector(
              onTap: () {
                if (item["screen"] != null) {
                  Navigator.push(
                    context,
                    slideFromRight(item["screen"]),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paleBlueBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item["icon"],
                      size: 40,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item["label"],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
