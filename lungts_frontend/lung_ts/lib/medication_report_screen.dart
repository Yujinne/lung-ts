import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';

class MedicationReportScreen extends StatefulWidget {
  const MedicationReportScreen({super.key});

  @override
  State<MedicationReportScreen> createState() =>
      _MedicationReportScreenState();
}

class _MedicationReportScreenState extends State<MedicationReportScreen> {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDay = DateTime.now();
  String selectedPeriod = '월별';
  bool isPeriodMenuOpen = false;

  List<Map<String, dynamic>> records = [];
  bool isLoading = true;
  String? errorMessage;
  bool animateCharts = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  String get apiDate =>
      '${selectedDate.year.toString().padLeft(4, '0')}-'
          '${selectedDate.month.toString().padLeft(2, '0')}-'
          '${selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _loadRecords() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      animateCharts = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인이 필요합니다.');
      }

      final String url;

      if (selectedPeriod == '일별') {
        url = 'http://localhost:8080/api/medication-records'
            '?date=$apiDate';
      } else if (selectedPeriod == '주별') {
        url = 'http://localhost:8080/api/medication-records/weekly'
            '?date=$apiDate';
      } else {
        url = 'http://localhost:8080/api/medication-records/monthly'
            '?year=${focusedDay.year}&month=${focusedDay.month}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('복약 기록 조회 실패 (${response.statusCode})');
      }

      final List<dynamic> data =
      jsonDecode(utf8.decode(response.bodyBytes));

      if (!mounted) return;

      setState(() {
        records = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          animateCharts = true;
        });
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _changeDate(int days) async {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });

    await _loadRecords();
  }

  void _goToPreviousMonth() {
    setState(() {
      focusedDay = DateTime(focusedDay.year, focusedDay.month - 1);
      selectedDate = DateTime(focusedDay.year, focusedDay.month, 1);
    });

    _loadRecords();
  }

  int get totalMedicationCount => filteredRecords.length;

  int get medicationDays {
    return filteredRecords
        .map((record) {
      final takenAt = DateTime.parse(record['takenAt'] as String);
      return DateTime(takenAt.year, takenAt.month, takenAt.day);
    })
        .toSet()
        .length;
  }

  List<Map<String, dynamic>> get filteredRecords => records;

  Map<String, int> get medicationCounts {
    final counts = <String, int>{};

    for (final record in filteredRecords) {
      final name = record['medicineName']?.toString() ?? '이름 없음';
      counts[name] = (counts[name] ?? 0) + 1;
    }

    return counts;
  }

  Map<int, int> get dailyMedicationCounts {
    final counts = <int, int>{};

    if (selectedPeriod == '주별') {
      final weekStart = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day - (selectedDate.weekday - 1),
      );

      for (int i = 0; i < 7; i++) {
        counts[i] = 0;
      }

      for (final record in records) {
        final takenAt = DateTime.parse(record['takenAt'] as String);
        final recordDate = DateTime(
          takenAt.year,
          takenAt.month,
          takenAt.day,
        );

        final index = recordDate.difference(weekStart).inDays;

        if (index >= 0 && index < 7) {
          counts[index] = counts[index]! + 1;
        }
      }
    } else if (selectedPeriod == '일별') {
      // 0시부터 23시까지 초기화
      for (int hour = 0; hour < 24; hour++) {
        counts[hour] = 0;
      }

      // 복약 기록을 시간대별로 집계
      for (final record in records) {
        final takenAt = DateTime.parse(record['takenAt'] as String);

        counts[takenAt.hour] = counts[takenAt.hour]! + 1;
      }
    } else {
      final daysInMonth = DateTime(
        focusedDay.year,
        focusedDay.month + 1,
        0,
      ).day;

      for (int day = 1; day <= daysInMonth; day++) {
        counts[day] = 0;
      }

      for (final record in records) {
        final takenAt = DateTime.parse(record['takenAt'] as String);
        if (takenAt.year == focusedDay.year &&
            takenAt.month == focusedDay.month) {
          counts[takenAt.day] = counts[takenAt.day]! + 1;
        }
      }
    }

    return counts;
  }

  void _goToNextMonth() {
    setState(() {
      focusedDay = DateTime(focusedDay.year, focusedDay.month + 1);
      selectedDate = DateTime(focusedDay.year, focusedDay.month, 1);
    });

    _loadRecords();
  }

  void _changePeriod(int direction) {
    setState(() {
      if (selectedPeriod == '일별') {
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day + direction,
        );
      } else if (selectedPeriod == '주별') {
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day + (7 * direction),
        );
      } else {
        focusedDay = DateTime(
          focusedDay.year,
          focusedDay.month + direction,
        );
        selectedDate = DateTime(focusedDay.year, focusedDay.month, 1);
      }

      focusedDay = DateTime(selectedDate.year, selectedDate.month);
    });

    _loadRecords();
  }

  String get periodDateLabel {
    if (selectedPeriod == '일별') {
      return '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일';
    }

    if (selectedPeriod == '주별') {
      final start = selectedDate.subtract(
        Duration(days: selectedDate.weekday - 1),
      );
      final end = start.add(const Duration(days: 6));

      return '${start.month}/${start.day} ~ ${end.month}/${end.day}';
    }

    return '${focusedDay.year}년 ${focusedDay.month.toString().padLeft(2, '0')}월';
  }

  void _selectYearMonth() {
    final int currentYear = focusedDay.year;
    final int currentMonthValue = focusedDay.month;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        int selectedYear = currentYear;
        int selectedMonth = currentMonthValue;

        return SizedBox(
          height: 250,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: currentYear - 2000,
                        ),
                        onSelectedItemChanged: (index) {
                          selectedYear = 2000 + index;
                        },
                        children: List.generate(50, (index) {
                          return Center(
                            child: Text('${2000 + index}년'),
                          );
                        }),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: currentMonthValue - 1,
                        ),
                        onSelectedItemChanged: (index) {
                          selectedMonth = index + 1;
                        },
                        children: List.generate(12, (index) {
                          return Center(
                            child: Text('${index + 1}월'),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  setState(() {
                    focusedDay = DateTime(selectedYear, selectedMonth);
                    selectedDate = DateTime(selectedYear, selectedMonth, 1);
                  });

                  _loadRecords();
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDay() async {
    DateTime tempDate = selectedDate;
    bool confirmed = false;

    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate,
                  minimumDate: DateTime(2000),
                  maximumDate: DateTime(2049, 12, 31),
                  dateOrder: DatePickerDateOrder.ymd,
                  onDateTimeChanged: (date) {
                    tempDate = date;
                  },
                ),
              ),
              SizedBox(
                height: 50,
                child: TextButton(
                  onPressed: () {
                    confirmed = true;
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || !confirmed) return;

    setState(() {
      selectedDate = tempDate;
      focusedDay = DateTime(tempDate.year, tempDate.month);
    });

    _loadRecords();
  }

  Widget _buildMedicationChart() {
    final entries = medicationCounts.entries.toList();

    if (entries.isEmpty) {
      return const Center(
        child: Text('복약 기록이 없습니다.'),
      );
    }

    final maxCount = entries
        .map((entry) => entry.value)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 130,
          child: BarChart(
            BarChartData(
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()}회',
                      const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              alignment: BarChartAlignment.spaceAround,

              maxY: (maxCount + 1).toDouble(),
              barGroups: List.generate(entries.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: animateCharts ? entries[index].value.toDouble() : 0,
                      color: const Color(0xFF3678C8),
                      width: 22,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          entries[index].key,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyMedicationChart() {
    final counts = dailyMedicationCounts;
    final maxCount = counts.values.reduce(
          (a, b) => a > b ? a : b,
    );

    return SizedBox(
      height: 130,
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.white,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String dateLabel;

                if (selectedPeriod == '일별') {
                  dateLabel = '${group.x.toString().padLeft(2, '0')}시';
                } else if (selectedPeriod == '주별') {
                  final weekStart = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day - (selectedDate.weekday - 1),
                  );

                  final date = weekStart.add(Duration(days: group.x));

                  dateLabel = '${date.month}월 ${date.day}일';
                } else {
                  dateLabel = '${focusedDay.month}월 ${group.x}일';
                }

                return BarTooltipItem(
                  '$dateLabel · ${rod.toY.toInt()}회',
                  const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxCount + 1).toDouble(),
          barGroups: counts.entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: animateCharts ? entry.value.toDouble() : 0,
                  color: const Color(0xFF3678C8),
                  width: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();

                  String label;

                  if (selectedPeriod == '일별') {
                    // 6시간 간격으로 표시
                    if (day % 6 != 0) {
                      return const SizedBox.shrink();
                    }

                    label = '$day시';
                  } else if (selectedPeriod == '주별') {
                    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

                    if (day < 0 || day >= 7) {
                      return const SizedBox.shrink();
                    }

                    label = weekdays[day];
                  } else {
                    if (day != 1 && day % 5 != 0) {
                      return const SizedBox.shrink();
                    }

                    label = '$day';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
        swapAnimationDuration: const Duration(milliseconds: 800),
        swapAnimationCurve: Curves.easeOutCubic,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    );

    Widget summaryItem(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget chartCard(String title, Widget chart) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            chart,
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - 32;
        final menuWidth = (contentWidth - 8) / 4;

        return Stack(
          children: [
            // 기본 화면
            Column(
              children: [
                // 고정된 상단 기간 및 날짜 선택 카드
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              setState(() {
                                isPeriodMenuOpen = !isPeriodMenuOpen;
                              });
                            },
                            child: SizedBox(
                              height: 40,
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text(
                                    selectedPeriod,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  AnimatedRotation(
                                    turns: isPeriodMenuOpen ? 0.5 : 0,
                                    duration:
                                    const Duration(milliseconds: 180),
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 17,
                                      color: Color(0xFF3678C8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => _changePeriod(-1),
                                icon: const Icon(Icons.chevron_left),
                                color: const Color(0xFF3678C8),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                              Flexible(
                                child: InkWell(
                                  onTap: () {
                                    if (selectedPeriod == '월별') {
                                      _selectYearMonth();
                                    } else {
                                      _selectDay();
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          periodDateLabel,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.calendar_month_rounded,
                                        size: 16,
                                        color: Color(0xFF3678C8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _changePeriod(1),
                                icon: const Icon(Icons.chevron_right),
                                color: const Color(0xFF3678C8),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 상단 카드는 고정, 보고서만 스크롤
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      if (isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        )
                      else ...[
                          if (selectedPeriod != '일별')
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$selectedPeriod 복약 현황',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      summaryItem(
                                        '총 복약 횟수',
                                        '$totalMedicationCount회',
                                      ),
                                      const SizedBox(width: 8),
                                      summaryItem(
                                        '복약 기록이 있는 날',
                                        '$medicationDays일',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          chartCard(
                            selectedPeriod == '일별'
                                ? '시간대별 복약 횟수'
                                : selectedPeriod == '주별'
                                ? '요일별 복약 횟수'
                                : '날짜별 복약 횟수',
                            _buildDailyMedicationChart(),
                          ),
                          const SizedBox(height: 12),
                          chartCard(
                            '약 종류별 복약 횟수',
                            _buildMedicationChart(),
                          ),
                          if (selectedPeriod == '일별') ...[
                            const SizedBox(height: 12),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '오늘의 복약 기록',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  if (records.isEmpty)
                                    const Text(
                                      '복약 기록이 없습니다.',
                                      style: TextStyle(color: Colors.grey),
                                    )
                                  else
                                    ...records.map((record) {
                                      final takenAt =
                                      DateTime.parse(record['takenAt'] as String);

                                      final time =
                                          '${takenAt.hour.toString().padLeft(2, '0')}:'
                                          '${takenAt.minute.toString().padLeft(2, '0')}';

                                      final medicineName =
                                          record['medicineName']?.toString() ?? '이름 없음';

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.medication_outlined,
                                              color: Color(0xFF3678C8),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                medicineName,
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            Text(
                                              time,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        ],
                    ],
                  ),
                ),
              ],
            ),

            // 보고서 위에 겹쳐 나타나는 드롭다운
            if (isPeriodMenuOpen)
              Positioned(
                top: 48,
                left: 16,
                width: menuWidth,
                child: Material(
                  elevation: 8,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ['일별', '주별', '월별'].map((period) {
                      final isSelected = selectedPeriod == period;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedPeriod = period;
                            isPeriodMenuOpen = false;
                          });

                          _loadRecords();
                        },
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          color: isSelected
                              ? const Color(0xFFEAF3FF)
                              : Colors.white,
                          child: Text(
                            period,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF3678C8)
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
