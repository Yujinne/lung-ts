
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'symptom_report_screen.dart';
import 'lung_log_screen.dart';
import 'medication_report_screen.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});
  static const Color _dark = Color(0xFF202936);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text(
            '보고서',
            style: TextStyle(
              color: _dark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: const Color(0xFFF9FAFB),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: Column(
          children: [
            // 상단 탭 카드
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF6B7280),
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                labelPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(height: 30, text: '증상'),
                  Tab(height: 30, text: '복약'),
                  Tab(height: 30, text: '폐소리'),
                ],
              ),
            ),

            // 보고서 내용
            Expanded(
              child: TabBarView(
                children: [
                  SymptomReportScreen(),

                  const MedicationReportScreen(),

                  LungLogScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
