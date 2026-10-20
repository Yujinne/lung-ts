
import 'package:flutter/material.dart';
import 'guideline.dart';
import 'home.dart';
import 'timer.dart';

class MeasurementScreen extends StatelessWidget {
  const MeasurementScreen({super.key});

  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color primaryBlue = Color(0xFF397DCB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '폐소리 측정',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
                  (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 650;
            final iconSize = 130.0;

            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Column(
                children: [
                  // 흰색 안내 카드
                Container(
                width: double.infinity,
                      padding: EdgeInsets.all(compact ? 20 : 26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '오늘의 호흡음을 기록해요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            '폐소리를 측정하고\n'
                                '호흡 상태의 변화를 확인해 보세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 45),

                          Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAF3FC),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.air,
                              size: iconSize * 0.55,
                              color: primaryBlue,
                            ),
                          ),

                          const SizedBox(height: 55),

                          const Text(
                            '측정 전 패치 부착 상태를 확인해 주세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 35),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: primaryBlue,
                                  size: 21,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '예상 측정 시간 약 10초',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 35),

                  // 카드 밖 측정 시작 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const TimerWithGaugeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '측정 시작',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 패치 부착 설명서
                  TextButton.icon(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) => const GuidelineScreen(),
                      );
                    },
                    icon: const Icon(
                      Icons.menu_book_outlined,
                      size: 19,
                    ),
                    label: const Text(
                      '패치 부착 방법 확인하기',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryBlue,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
