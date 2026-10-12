import 'package:flutter/material.dart';
import 'symptom_report_screen.dart';
import 'lung_log_screen.dart';
import 'package:lung_ts/app_colors.dart';
import 'package:lung_ts/transition_helper.dart';

class ReportScreen extends StatefulWidget {
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.3), // 아래에서
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('보고서'),
        backgroundColor: AppColors.lightBlueBg,
      ),
      body: Container(
        width: double.infinity,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: _offsetAnimation,
                child: _buildReportCard(
                  context,
                  title: '증상 보고서',
                  icon: Icons.assignment,
                  onTap: () => Navigator.push(
                    context,
                    slideFromRight(SymptomReportScreen()),
                  ),
                ),
              ),
              SizedBox(height: 24),
              SlideTransition(
                position: _offsetAnimation,
                child: _buildReportCard(
                  context,
                  title: '음성 측정 기록',
                  icon: Icons.graphic_eq,
                  onTap: () => Navigator.push(
                    context,
                      slideFromRight(LungLogScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.paleBlueBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppColors.primaryBlue),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
