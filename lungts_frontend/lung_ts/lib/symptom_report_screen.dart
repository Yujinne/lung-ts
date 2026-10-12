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

class _SymptomReportScreenState extends State<SymptomReportScreen> {
  DateTime currentMonth = DateTime.now();
  bool animateBars = false;
  bool animateChart = false;
  Map<String, dynamic>? symptomTimeData;

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
  }


  void _goToPreviousMonth() async {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
      symptomTimeData = null; // <-- 그래프 초기화
      symptomCounts = null;
      animateChart = false;
    });
    await _loadSymptomCounts();
  }

  void _goToNextMonth() async {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
      symptomTimeData = null; // <-- 그래프 초기화
      symptomCounts = null;
      animateChart = false;
    });
    await _loadSymptomCounts();
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

      final response = await http.get(
        Uri.parse(
          'http://localhost:8080/api/diaries/statistics'
              '?year=${currentMonth.year}'
              '&month=${currentMonth.month}',
        ),
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

      if (!mounted) return;

      setState(() {
        symptomCounts = counts;
        symptomTimeData = timeData;

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
          // ✅ 동적으로 maxY 설정
          barGroups: barGroups,
          barTouchData: BarTouchData( // 툴팁 설정
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black87,
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
                  const TextStyle(color: Colors.white, fontSize: 12),
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


  @override
  Widget build(BuildContext context) {
    String formattedMonth = DateFormat('yyyy년 MM월').format(currentMonth);

    return Scaffold(
      appBar: AppBar(title: const Text("증상 보고서")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 월 변경 위젯
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                    onPressed: _goToPreviousMonth, child: const Text("이전")),
                GestureDetector(
                  onTap: _showYearMonthPicker,
                  child: Text(
                    formattedMonth,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(onPressed: _goToNextMonth, child: const Text("다음")),
              ],
            ),
          ),

          const Divider(),

          // 증상 빈도 라벨 및 색상표
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "증상 빈도",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ✅ 여기에 조건부 UI 표시
                symptomCounts == null
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSymptomBarAnimated(symptomCounts!, symptomColors),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
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
                            Text(entry.key),
                            const SizedBox(width: 6),
                            Text('${count}회',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),


          const Divider(),

          // 이후 시간대별 증상 추가 예정
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("시간대별 증상",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          symptomTimeData == null || !hasTimeSlotData(symptomTimeData!)
              ? Center(child: Text("시간대별 증상 데이터가 없습니다."))
              : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSymptomTimeBarChart(symptomTimeData!),
          ),
        ],
      ),
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