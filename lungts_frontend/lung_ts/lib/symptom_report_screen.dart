//증상 보고서
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class SymptomReportScreen extends StatefulWidget {
  const SymptomReportScreen({super.key});

  @override
  State<SymptomReportScreen> createState() => _SymptomReportScreenState();
}

class _SymptomReportScreenState extends State<SymptomReportScreen>
    with AutomaticKeepAliveClientMixin<SymptomReportScreen> {

  @override
  bool get wantKeepAlive => true;
  DateTime currentMonth = DateTime.now();

  DateTime selectedDate = DateTime.now();
  String selectedPeriod = '월별';
  bool isPeriodMenuOpen = false;

  bool animateBars = false;
  bool animateChart = false;
  Map<String, dynamic>? symptomTimeData;
  Map<String, dynamic>? symptomDateData;
  List<Map<String, dynamic>> dailyDiaries = [];
  bool isDiaryLoading = false;

  @override
  void initState() {
    super.initState();
    // 0.1초 후 애니메이션 시작
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        animateBars = true;
      });
    });
    _loadSymptomCounts();
    if (selectedPeriod == '일별') {
      _loadDailyDiaries();
    }
  }

  void _changePeriod(int direction) {
    setState(() {
      if (selectedPeriod == '일별') {
        selectedDate = selectedDate.add(
          Duration(days: direction),
        );
      } else if (selectedPeriod == '주별') {
        selectedDate = selectedDate.add(
          Duration(days: 7 * direction),
        );
      } else {
        currentMonth = DateTime(
          currentMonth.year,
          currentMonth.month + direction,
        );
      }

      symptomCounts = null;
      symptomTimeData = null;
      symptomDateData = null;
      dailyDiaries = [];
      animateBars = false;
      animateChart = false;
    });

    _loadSymptomCounts();
    if (selectedPeriod == '일별') {
      _loadDailyDiaries();
    }
  }

  void _showYearMonthPicker() {
    final int currentYear = currentMonth.year;
    final int currentMonthValue = currentMonth.month;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        int selectedYear = currentYear;
        int selectedMonth = currentMonthValue;

        return Container(
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
                            initialItem: currentYear - 2000),
                        onSelectedItemChanged: (index) {
                          selectedYear = 2000 + index;
                        },
                        children: List.generate(50, (index) {
                          return Center(child: Text('${2000 + index}년'));
                        }),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                            initialItem: currentMonthValue - 1),
                        onSelectedItemChanged: (index) {
                          selectedMonth = index + 1;
                        },
                        children: List.generate(12, (index) {
                          return Center(child: Text('${index + 1}월'));
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
                    currentMonth = DateTime(selectedYear, selectedMonth);
                    animateChart = false;
                  });
                  _loadSymptomCounts();
                },
                child: Text("확인"),
              )
            ],
          ),
        );
      },
    );
  }

  void _showDatePicker() {
    if (selectedPeriod == '월별') {
      _showYearMonthPicker();
      return;
    }

    DateTime tempDate = selectedDate;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate,
                  dateOrder: DatePickerDateOrder.ymd,
                  onDateTimeChanged: (date) {
                    tempDate = date;
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  setState(() {
                    selectedDate = tempDate;
                    symptomCounts = null;
                    symptomTimeData = null;
                    animateBars = false;
                    animateChart = false;
                  });

                  _loadSymptomCounts();
                  if (selectedPeriod == '일별') {
                    _loadDailyDiaries();
                  }
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      },
    );
  }


  final Map<String, Color> symptomColors = {
    '기침': Color(0xFFB3CDE0), // 연한 인디고 블루
    '가래': Color(0xFFCCE2FF), // 하늘 파랑
    '가슴답답함': Color(0xFFD0EBFF), // 아이스 블루
    '호흡곤란': Color(0xFFFFF3B0), // 연노랑
    '천명음': Color(0xFFC2F0C2), // 연녹색
    '기타증상': Color(0xFFD2F5F2), // 민트톤
    '증상없음': Color(0xFFEEEEEE), // 연회색
  };

  Widget buildSymptomBarAnimated(Map<String, int> symptomCounts,
      Map<String, Color> colors) {
    final total = symptomCounts.values.fold(0, (sum, value) => sum + value);

    if (total == 0) {
      return Container(
        height: 20,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }

    final List<Map<String, dynamic>> barSegments = symptomColors.keys
        .where((symptom) =>
    symptomCounts[symptom] != null && symptomCounts[symptom]! > 0)
        .map((symptom) =>
    {
      'label': symptom,
      'color': colors[symptom]!,
      'ratio': symptomCounts[symptom]! / total,
    })
        .toList();

    return Container(
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // 배경 (회색)
          Container(color: Colors.grey[200]),

          // Animated foreground bar
          AnimatedContainer(
            duration: Duration(milliseconds: 800),
            width: animateBars ? MediaQuery
                .of(context)
                .size
                .width - 32 : 0,
            curve: Curves.easeOut,
            child: Row(
              children: barSegments.map((seg) {
                return Expanded(
                  flex: (seg['ratio'] * 1000).toInt(), // 비율 기반으로 flex 계산
                  child: Container(color: seg['color']),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }


  Map<String, int>? symptomCounts;

  Future<void> _loadSymptomCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인 정보가 없습니다.');
      }

      String apiUrl;

      if (selectedPeriod == '일별') {
        final date = DateFormat('yyyy-MM-dd').format(selectedDate);

        apiUrl =
        'http://localhost:8080/api/diaries/statistics/daily?date=$date';
      } else if (selectedPeriod == '주별') {
        final date = DateFormat('yyyy-MM-dd').format(selectedDate);

        apiUrl =
        'http://localhost:8080/api/diaries/statistics/weekly?date=$date';
      } else {
        apiUrl =
        'http://localhost:8080/api/diaries/statistics'
            '?year=${currentMonth.year}'
            '&month=${currentMonth.month}';
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          '증상 통계 조회 실패: ${response.statusCode}',
        );
      }

      final Map<String, dynamic> data =
      jsonDecode(utf8.decode(response.bodyBytes));

      final Map<String, int> counts =
      Map<String, int>.from(
        data['symptomCounts'] ?? {},
      );

      final Map<String, dynamic> timeData =
      Map<String, dynamic>.from(
        data['symptomTimeData'] ?? {},
      );

      final Map<String, dynamic> dateData =
      Map<String, dynamic>.from(
        data['symptomDateData'] ?? {},
      );

      if (!mounted) return;

      setState(() {
        symptomCounts = counts;
        symptomTimeData = timeData;
        symptomDateData = dateData;

        animateBars = false;
        animateChart = false;
      });

      Future.delayed(
        const Duration(milliseconds: 200),
            () {
          if (!mounted) return;

          setState(() {
            animateBars = true;
            animateChart = true;
          });
        },
      );
    } catch (e) {
      print('증상 통계 조회 실패: $e');

      if (!mounted) return;

      setState(() {
        symptomCounts = {};
        symptomTimeData = {};
        symptomDateData = {};
      });
    }
  }

  Future<void> _loadDailyDiaries() async {
    if (selectedPeriod != '일별') return;

    setState(() {
      isDiaryLoading = true;
      dailyDiaries = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8080/api/diaries'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('일기 조회 실패: ${response.statusCode}');
      }

      final List<dynamic> data =
      jsonDecode(utf8.decode(response.bodyBytes));

      final selectedDay = DateFormat('yyyy-MM-dd').format(selectedDate);

      final filtered = data.where((diary) {
        final occurredAt = diary['occurredAt']?.toString();

        if (occurredAt == null) return false;

        final date = DateTime.tryParse(occurredAt);

        if (date == null) return false;

        return DateFormat('yyyy-MM-dd').format(date) == selectedDay;
      }).map((diary) {
        return Map<String, dynamic>.from(diary);
      }).toList();

      filtered.sort((a, b) =>
          (a['occurredAt'] as String)
              .compareTo(b['occurredAt'] as String));

      if (!mounted) return;

      setState(() {
        dailyDiaries = filtered;
        isDiaryLoading = false;
      });
    } catch (e) {
      debugPrint('일별 증상 일기 조회 실패: $e');

      if (!mounted) return;

      setState(() {
        dailyDiaries = [];
        isDiaryLoading = false;
      });
    }
  }

  Widget _buildSymptomTimeBarChart(Map<String, dynamic> timeData) {
    final timeSlots = ['새벽', '오전', '오후', '저녁'];
    final symptoms = symptomColors.keys.toList();

    List<BarChartGroupData> barGroups = [];
    int maxCount = 0; // <-- 여기에 최대값 저장

    for (int i = 0; i < timeSlots.length; i++) {
      final slot = timeSlots[i];
      final data = Map<String, dynamic>.from(timeData[slot] ?? {});
      int slotTotal = 0;
      double runningHeight = 0;
      List<BarChartRodStackItem> stacks = [];

      for (final symptom in symptoms) {
        final count = (data[symptom] ?? 0) as int;
        slotTotal += count;
        if (count > 0) {
          stacks.add(
            BarChartRodStackItem(
              runningHeight,
              runningHeight + count,
              symptomColors[symptom]!,
            ),
          );
          runningHeight += count;
        }
      }

      maxCount = slotTotal > maxCount ? slotTotal : maxCount;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: animateChart ? runningHeight : 0,
              width: 90,
              rodStackItems: stacks.map((item) {
                return BarChartRodStackItem(
                  animateChart ? item.fromY : 0,
                  animateChart ? item.toY : 0,
                  item.color,
                );
              }).toList(),
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }

    // maxY를 1 이상으로 보장
    final adjustedMaxY = (maxCount <= 5) ? 5.0 : (maxCount + 1).toDouble();

    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          maxY: adjustedMaxY,
          barGroups: barGroups,
          barTouchData: BarTouchData( // 툴팁 설정
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.white,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final timeSlots = ['새벽', '오전', '오후', '저녁'];
                final slot = timeSlots[group.x.toInt()];
                final data = Map<String, dynamic>.from(timeData[slot] ?? {});

                final List<String> lines = [];
                for (final symptom in symptomColors.keys) {
                  final count = data[symptom] ?? 0;
                  if (count > 0) {
                    lines.add('$symptom ${count}회');
                  }
                }

                return BarTooltipItem(
                  lines.join('\n'),
                  const TextStyle(color: Colors.black87, fontSize: 12),
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true, // 세로 방향 그리드
            drawVerticalLine: false, // 가로 방향 안씀
            getDrawingHorizontalLine: (value) {
              if (value % 2 == 0 || value == 0) {
                return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
              }
              return FlLine(color: Colors.transparent);
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, _) {
                  return Text(
                      value.toInt().toString(), style: TextStyle(fontSize: 12));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                        timeSlots[index], style: TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomDateBarChart(Map<String, dynamic> dateData) {
    final DateTime startDate;
    final int dayCount;

    if (selectedPeriod == '주별') {
      startDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day - (selectedDate.weekday - 1),
      );
      dayCount = 7;
    } else {
      startDate = DateTime(currentMonth.year, currentMonth.month, 1);
      dayCount = DateTime(
        currentMonth.year,
        currentMonth.month + 1,
        0,
      ).day;
    }

    final dates = List.generate(
      dayCount,
          (index) => startDate.add(Duration(days: index)),
    );

    final totals = dates.map((date) {
      final key = DateFormat('yyyy-MM-dd').format(date);
      final symptoms = Map<String, dynamic>.from(dateData[key] ?? {});

      return symptoms.values.fold<int>(
        0,
            (sum, count) => sum + (count as num).toInt(),
      );
    }).toList();

    final maxCount = totals.fold<int>(
      0,
          (max, count) => count > max ? count : max,
    );

    final groups = List.generate(dates.length, (index) {
      final dateKey = DateFormat('yyyy-MM-dd').format(dates[index]);

      final daySymptoms = Map<String, dynamic>.from(
        dateData[dateKey] ?? {},
      );

      double runningHeight = 0;
      final List<BarChartRodStackItem> stacks = [];

      for (final symptom in symptomColors.keys) {
        final count = (daySymptoms[symptom] as num?)?.toDouble() ?? 0;

        if (count <= 0) continue;

        stacks.add(
          BarChartRodStackItem(
            runningHeight,
            runningHeight + count,
            symptomColors[symptom]!,
          ),
        );

        runningHeight += count;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: animateChart ? runningHeight : 0,
            width: selectedPeriod == '주별' ? 20 : 7,
            rodStackItems: stacks.map((item) {
              return BarChartRodStackItem(
                animateChart ? item.fromY : 0,
                animateChart ? item.toY : 0,
                item.color,
              );
            }).toList(),
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    });

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: (maxCount < 5 ? 5 : maxCount + 1).toDouble(),
          barGroups: groups,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.white,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final date = dates[group.x.toInt()];
                final dateKey = DateFormat('yyyy-MM-dd').format(date);

                final daySymptoms = Map<String, dynamic>.from(
                  dateData[dateKey] ?? {},
                );

                final lines = <String>[
                  DateFormat('MM/dd').format(date),
                ];

                for (final symptom in symptomColors.keys) {
                  final count = (daySymptoms[symptom] as num?)?.toInt() ?? 0;

                  if (count > 0) {
                    lines.add('$symptom ${count}회');
                  }
                }

                if (lines.length == 1) {
                  lines.add('증상 기록 없음');
                }

                return BarTooltipItem(
                  lines.join('\n'),
                  const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= dates.length) {
                    return const SizedBox.shrink();
                  }

                  if (selectedPeriod == '주별') {
                    return Text(
                      ['월', '화', '수', '목', '금', '토', '일'][index],
                      style: const TextStyle(fontSize: 11),
                    );
                  }

                  final day = dates[index].day;

                  if (day != 1 && day % 5 != 0) {
                    return const SizedBox.shrink();
                  }

                  return Text(
                    '$day',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 800),
        swapAnimationCurve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final formattedDate = selectedPeriod == '월별'
        ? DateFormat('yyyy년 MM월').format(currentMonth)
        : selectedPeriod == '일별'
        ? DateFormat('yyyy년 M월 d일').format(selectedDate)
        : '${DateFormat('M/d').format(
      selectedDate.subtract(
        Duration(days: selectedDate.weekday - 1),
      ),
    )} ~ ${DateFormat('M/d').format(
      selectedDate.add(
        Duration(days: 7 - selectedDate.weekday),
      ),
    )}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - 32;
        final menuWidth = (contentWidth - 8) / 4;

        return Stack(
          children: [
            Container(
              color: const Color(0xFFF9FAFB),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child:
                    // 기간 및 날짜 선택
                    Row(
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      selectedPeriod,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    AnimatedRotation(
                                      turns: isPeriodMenuOpen ? 0.5 : 0,
                                      duration: const Duration(milliseconds: 180),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => _changePeriod(-1),
                                  icon: const Icon(Icons.chevron_left),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                                Flexible(
                                  child: InkWell(
                                    onTap: _showDatePicker,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontSize: 15,
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

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        // 증상 빈도 카드
                        _reportCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$selectedPeriod 증상 빈도',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (symptomCounts == null)
                                const Center(
                                  child: CircularProgressIndicator(),
                                )
                              else ...[
                                buildSymptomBarAnimated(
                                  symptomCounts!,
                                  symptomColors,
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 16,
                                    runSpacing: 12,
                                    children: symptomColors.entries.map((entry) {
                                      final count = symptomCounts![entry.key] ?? 0;

                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: entry.value,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            entry.key,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${count}회',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 시간대별 증상 카드
                        _reportCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedPeriod == '일별'
                                    ? '시간대별 증상'
                                    : selectedPeriod == '주별'
                                    ? '주간 시간대별 증상'
                                    : '월간 시간대별 증상',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (symptomTimeData == null)
                                const Center(
                                  child: CircularProgressIndicator(),
                                )
                              else if (selectedPeriod == '일별' &&
                                  !hasTimeSlotData(symptomTimeData!))
                                const SizedBox(
                                  height: 140,
                                  child: Center(
                                    child: Text(
                                      '시간대별 증상 데이터가 없습니다.',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                )
                              else if (selectedPeriod == '일별')
                                  _buildSymptomTimeBarChart(symptomTimeData!)
                                else if (symptomDateData == null)
                                    const Center(child: CircularProgressIndicator())
                                  else
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 날짜별 증상 그래프
                                        _buildSymptomDateBarChart(symptomDateData!),

                                        const SizedBox(height: 20),

                                        SizedBox(
                                          width: double.infinity,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: 16,
                                                runSpacing: 12,
                                                children: symptomColors.entries.take(4).map((entry) {
                                                  return _buildSymptomLegend(entry.key, entry.value);
                                                }).toList(),
                                              ),

                                              const SizedBox(height: 12),

                                              Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: 16,
                                                runSpacing: 12,
                                                children: symptomColors.entries.skip(4).map((entry) {
                                                  return _buildSymptomLegend(entry.key, entry.value);
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                        // 일별 증상 기록 목록
                        if (selectedPeriod == '일별') ...[
                          const SizedBox(height: 16),
                          _buildDailyDiaryCard(),
                        ],
                      ], // ListView children
                    ),
                  ),
                ], // Column children
              ),
            ),
            // 기간 선택 드롭다운
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
                            if (selectedPeriod == '월별' && period != '월별') {
                              final lastDay = DateTime(
                                currentMonth.year,
                                currentMonth.month + 1,
                                0,
                              ).day;

                              selectedDate = DateTime(
                                currentMonth.year,
                                currentMonth.month,
                                selectedDate.day.clamp(1, lastDay),
                              );
                            } else if (selectedPeriod != '월별' &&
                                period == '월별') {
                              currentMonth = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                              );
                            }

                            selectedPeriod = period;
                            isPeriodMenuOpen = false;

                            symptomCounts = null;
                            symptomTimeData = null;
                            symptomDateData = null;
                            dailyDiaries = [];
                            animateBars = false;
                            animateChart = false;
                          });

                          _loadSymptomCounts();

                          if (selectedPeriod == '일별') {
                            _loadDailyDiaries();
                          }
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
          ], // Stack children
        );
      },
    );
  }

  Widget _buildDailyDiaryCard() {
    return _reportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '선택한 날짜의 증상 기록',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (isDiaryLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (dailyDiaries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '해당 날짜에 증상 기록이 없습니다.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...dailyDiaries.map((diary) {
              final occurredAt = DateTime.tryParse(
                diary['occurredAt']?.toString() ?? '',
              );

              final time = occurredAt == null
                  ? '--:--'
                  : DateFormat('HH:mm').format(occurredAt);

              final symptoms = List<String>.from(
                diary['symptoms'] ?? [],
              );

              final memo = diary['memo']?.toString() ?? '';

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 17,
                          color: Color(0xFF3678C8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: symptoms.map((symptom) {
                        final color =
                            symptomColors[symptom] ?? Colors.grey.shade200;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            symptom,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (memo.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        memo,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSymptomLegend(String name, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // 하얀 카드 공통 디자인
  Widget _reportCard({
    required Widget child,
    double verticalPadding = 18,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: verticalPadding,
      ),
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
      child: child,
    );
  }


  bool hasTimeSlotData(Map<String, dynamic> data) {
    for (final value in data.values) {
      if (value is Map<String, dynamic>) {
        for (final count in value.values) {
          if (count is int && count > 0) return true;
          if (count is double && count > 0) return true;
          if (count is String && int.tryParse(count) != null && int.parse(count) > 0) return true;
        }
      }
    }
    return false;
  }


}