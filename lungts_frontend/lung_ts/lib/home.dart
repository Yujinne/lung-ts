import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'diary_list_screen.dart';
import 'measurement.dart';
import 'act_screen.dart';
import 'report_screen.dart';
import 'mypage.dart';
import 'transition_helper.dart';
import 'medication_record_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'medication_record_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> medicationRecords = [];
  bool isLoadingRecords = false;

  @override
  void initState() {
    super.initState();
    loadMedicationRecords();
  }

  void changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });

    loadMedicationRecords();
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

      loadMedicationRecords();
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

  Future<void> loadMedicationRecords() async {
    setState(() {
      isLoadingRecords = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final date =
          '${selectedDate.year.toString().padLeft(4, '0')}-'
          '${selectedDate.month.toString().padLeft(2, '0')}-'
          '${selectedDate.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        // 복약 기록 등록 화면에서 사용한 서버 주소와 동일하게 설정
        Uri.parse(
          'http://localhost:8080/api/medication-records?date=$date',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('복약 기록 조회 실패: ${response.statusCode}');
      }

      final List<dynamic> data =
      jsonDecode(utf8.decode(response.bodyBytes));

      if (!mounted) return;

      setState(() {
        medicationRecords = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        isLoadingRecords = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        medicationRecords = [];
        isLoadingRecords = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              height: 55,
              fit: BoxFit.contain,
            ),
            IconButton(
              onPressed: () {
                openScreen(const MyPageScreen());
              },
              icon: const Icon(
                Icons.account_circle_outlined,
                color: Color(0xFF6B7280),
                size: 30,
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
                                      Navigator.push(
                                        context,
                                        slideFromRight(screen),
                                      ).then((_) {
                                        if (mounted) {
                                          loadMedicationRecords();
                                        }
                                      });
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
                onPressed: () async {
                  await Navigator.push(
                    context,
                    slideFromRight(
                      MedicationRecordListScreen(
                        selectedDate: selectedDate,
                      ),
                    ),
                  );

                  if (mounted) {
                    loadMedicationRecords();
                  }
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

          SizedBox(
            height: 170,
            child: isLoadingRecords
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : medicationRecords.isEmpty
                ? const Center(
              child: Text('복약 기록이 없습니다.'),
            )
                : ListView.builder(
              itemCount: medicationRecords.length,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                final record = medicationRecords[index];

                final takenAt =
                DateTime.parse(record['takenAt'] as String);

                final time =
                    '${takenAt.hour.toString().padLeft(2, '0')}:'
                    '${takenAt.minute.toString().padLeft(2, '0')}';

                final medicineName =
                record['medicineName'] as String;

                final dose = record['dose'];
                final doseUnit = record['doseUnit'] as String? ?? '';

                return InkWell(
                    onTap: () async {
                  await Navigator.push(
                    context,
                    slideFromRight(
                      MedicationRecordListScreen(
                        selectedDate: selectedDate,
                      ),
                    ),
                  );

                  if (mounted) {
                    loadMedicationRecords();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // 왼쪽: 복용 시간
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // 가운데: 약 이름
                      Expanded(
                        child: Text(
                          medicineName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 오른쪽: 복용량
                      Text(
                        '$dose $doseUnit',
                        style: const TextStyle(
                          fontSize: 13,
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

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final saved = await Navigator.push<bool>(
                  context,
                  slideFromRight(
                    MedicationRecordScreen(
                      selectedDate: selectedDate,
                    ),
                  ),
                );

                if (saved == true && mounted) {
                  loadMedicationRecords();
                }
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
