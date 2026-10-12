
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_colors.dart';
import 'diary_list_screen.dart';
import 'measurement.dart';
import 'act_screen.dart';
import 'report_screen.dart';
import 'mypage.dart';
import 'transition_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();

  void changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3678C8),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String get formattedDate {
    return '${selectedDate.year}년 '
        '${selectedDate.month}월 '
        '${selectedDate.day}일';
  }

  void openScreen(Widget screen) {
    Navigator.push(
      context,
      slideFromRight(screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final menuItems = [
      {
        'title': '일기장',
        'description': '오늘의 증상을 기록해요',
        'icon': Icons.menu_book_rounded,
        'screen': const DiaryListScreen(),
      },
      {
        'title': '폐소리',
        'description': '호흡음을 측정하고 기록해요',
        'icon': Icons.graphic_eq_rounded,
        'screen': const MeasurementScreen(),
      },
      {
        'title': 'ACT',
        'description': '천식 조절 검사를 진행해요',
        'icon': Icons.fact_check_rounded,
        'screen': ActScreen(),
      },
      {
        'title': '보고서',
        'description': '나의 변화를 확인해요',
        'icon': Icons.bar_chart_rounded,
        'screen': ReportScreen(),
      },
      {
        'title': '커뮤니티',
        'description': '다른 사용자들과\n이야기를 나눠요',
        'icon': Icons.forum_rounded,
        'screen': null,
      },
      {
        'title': '등록',
        'description': '필요한 정보를\n등록하고 관리해요',
        'icon': Icons.add_box_rounded,
        'screen': null,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 65,
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 40,
              fit: BoxFit.contain,
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyPageScreen(),
                  ),
                );
              },
              icon: Image.asset(
                'assets/mypage.png',
                height: 32,
              ),
            ),
          ],
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                child: Column(
                  children: [
                    _buildMedicationCard(),

                    const SizedBox(height: 16),

                    LayoutBuilder(
                      builder: (context, gridConstraints) {
                        final cardWidth =
                            (gridConstraints.maxWidth - 20) / 3;

                        // 창 높이에 맞춰 카드 높이 자동 계산
                        final remainingHeight =
                            constraints.maxHeight - 5 - 16 - 367;

                        final cardHeight =
                        ((remainingHeight - 10) / 2)
                            .clamp(70.0, 140.0);

                        return GridView.builder(
                          shrinkWrap: true,
                          physics:
                          const NeverScrollableScrollPhysics(),
                          itemCount: menuItems.length,
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio:
                            cardWidth / cardHeight,
                          ),
                          itemBuilder: (context, index) {
                            final item = menuItems[index];

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius:
                                BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  onTap: () {
                                    final screen = item['screen'];

                                    if (screen is Widget) {
                                      openScreen(screen);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '준비 중인 기능입니다.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: LayoutBuilder(
                                    builder: (context, size) {
                                      final scale =
                                      (size.maxHeight / 110)
                                          .clamp(0.65, 1.0);

                                      return Padding(
                                        padding:
                                        const EdgeInsets.all(5),
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              item['icon']
                                              as IconData,
                                              size: 23 * scale,
                                              color:
                                              AppColors.primaryBlue,
                                            ),
                                            SizedBox(
                                                height: 5 * scale),
                                            Text(
                                              item['title'] as String,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow:
                                              TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15 * scale,
                                                fontWeight:
                                                FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(
                                                height: 3 * scale),
                                            Flexible(
                                              child: Text(
                                                item['description']
                                                as String,
                                                textAlign:
                                                TextAlign.center,
                                                maxLines: 2,
                                                overflow:
                                                TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12 * scale,
                                                  color:
                                                  Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedicationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '복약 기록',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: 복약 기록 전체 보기 화면 연결
                },
                child: const Text(
                  '전체 보기 >',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => changeDate(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: selectDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: Color(0xFF3678C8),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => changeDate(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 50,
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 30,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  '복약 기록이 없습니다.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: 복약 기록 등록 화면 연결
              },
              icon: const Icon(Icons.add),
              label: const Text('복약 기록하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
