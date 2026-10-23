// 음성 측정 기록
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'lung_sound_detail_screen.dart';


class LungLogScreen extends StatefulWidget {
  @override
  State<LungLogScreen> createState() => _LungLogScreenState();

}

class _LungLogScreenState extends State<LungLogScreen>
    with AutomaticKeepAliveClientMixin<LungLogScreen> {

  @override
  bool get wantKeepAlive => true;
  Set<DateTime> measuredDates = {};
  Map<String, List<Map<String, dynamic>>> fileTimes = {};

  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadVoiceLogs();
  }


  @override
  void dispose() {
    super.dispose();
  }

  List<Map<String, dynamic>> getTimesForDay(DateTime day) {
    final key =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

    return fileTimes[key] ?? [];
  }



  Widget _buildRecordingDay(
      DateTime day, {
        bool isToday = false,
        bool isSelected = false,
        bool isOutside = false,
      }) {
    final int count = getTimesForDay(day).length;
    final bool hasRecordings = count > 0;

    // 실제 오늘 날짜인지 확인
    final bool today = isSameDay(day, DateTime.now());

    final Color backgroundColor = isSelected
        ? const Color(0xFF377DCE)
        : today
        ? const Color(0xFFDCEBFF)
        : hasRecordings
        ? const Color(0xFFEAF3FF)
        : Colors.transparent;

    final Color textColor = isSelected
        ? Colors.white
        : isOutside
        ? Colors.grey.shade400
        : today || hasRecordings
        ? const Color(0xFF3678C8)
        : const Color(0xFF202936);

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: today || isSelected
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: textColor,
              ),
            ),

            if (today || hasRecordings) ...[
              const SizedBox(height: 1),
              Text(
                today
                    ? (hasRecordings ? '오늘·$count개' : '오늘')
                    : '$count개',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF3678C8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      focusedDay = DateTime(focusedDay.year, focusedDay.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      focusedDay = DateTime(focusedDay.year, focusedDay.month + 1);
    });
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
                    selectedDay = DateTime(selectedYear, selectedMonth, 1);
                  });
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadVoiceLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8080/api/lung-sounds'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          '음성 측정 기록 조회 실패: ${response.statusCode}',
        );
      }

      final List<dynamic> data =
      jsonDecode(utf8.decode(response.bodyBytes));

      final Map<String, List<Map<String, dynamic>>> newFileTimes = {};
      final Set<DateTime> newMeasuredDates = {};

      for (final item in data) {
        final recordedAtString = item['recordedAt'];

        if (recordedAtString == null) {
          continue;
        }

        final recordedAt = DateTime.parse(recordedAtString);

        final year = recordedAt.year;
        final month = recordedAt.month;
        final day = recordedAt.day;

        newMeasuredDates.add(
          DateTime(year, month, day),
        );

        final dateKey =
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(
            2, '0')}';

        final time =
            '${recordedAt.hour.toString().padLeft(2, '0')}'
            '${recordedAt.minute.toString().padLeft(2, '0')}';

        newFileTimes.putIfAbsent(dateKey, () => []);

        newFileTimes[dateKey]!.add({
          'id': item['id'],
          'time': time,
        });
      }

      if (!mounted) return;

      setState(() {
        measuredDates = newMeasuredDates;
        fileTimes = newFileTimes;
      });
    } catch (e) {
      print('음성 측정 기록 조회 실패: $e');

      if (!mounted) return;

      setState(() {
        measuredDates = {};
        fileTimes = {};
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);

    final times = getTimesForDay(selectedDay);
    final selectedKey = "${selectedDay.year}-${selectedDay.month
        .toString()
        .padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";

    return Container(
      color: const Color(0xFFF9FAFB),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 이전/다음 월 이동 버튼
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 18),
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
                  onPressed: _goToPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                InkWell(
                  onTap: _selectYearMonth,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${focusedDay.year}년 ${focusedDay.month.toString().padLeft(2, '0')}월',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 19,
                          color: Color(0xFF3678C8),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _goToNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
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
              children: [
                TableCalendar(
                  onPageChanged: (day) {
                    setState(() {
                      focusedDay = day;
                    });
                  },
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  focusedDay: focusedDay,
                  selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDay = selected;
                      focusedDay = focused;
                    });
                  },
                  headerVisible: false,

                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildRecordingDay(day);
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _buildRecordingDay(day, isToday: true);
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return _buildRecordingDay(day, isSelected: true);
                    },
                    outsideBuilder: (context, day, focusedDay) {
                      return _buildRecordingDay(day, isOutside: true);
                    },
                  ),

                ),

                const Divider(height: 24),

                if (times.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('선택한 날짜에 저장된 음성이 없습니다.'),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: times.length,
                      itemBuilder: (context, index) {
                        final record = times[index];
                        final int resultId = (record['id'] as num).toInt();
                        final String time = record['time'] as String;
                        final formatted = "${time.substring(0, 2)}:${time
                            .substring(2)}";


                        // 가정: 저장된 경로는 이와 같은 형식임. 필요 시 수정
                        final datePath = selectedKey.replaceAll(
                            '-', '.'); // "2025.05.14"
                        final voiceUrl =
                            'http://localhost:8080/api/lung-sounds/$resultId/audio';

                        return Column(
                          children: [
                            ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LungSoundDetailScreen(
                                      resultId: resultId,
                                      recordedTime: formatted,
                                      records: times,
                                    ),
                                  ),
                                );
                              },
                        title: Text("$formatted 측정 음성"),
                        trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.black54,
                        ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}