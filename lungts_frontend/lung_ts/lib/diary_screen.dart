import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class DiaryScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData; // 기존 데이터를 받을 수 있도록 수정

  const DiaryScreen({super.key, required this.onSave, this.initialData});

  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  Set<String> selectedSymptoms = {};
  TextEditingController memoController = TextEditingController();

  final List<String> symptoms = [
    "기침",
    "가래",
    "가슴답답함",
    "호흡곤란",
    "천명음",
    "기타증상",
    "증상없음"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      selectedDate =
          DateFormat('yy/MM/dd').parse(widget.initialData!["date"]!); // 형식 맞춤
      selectedTime = TimeOfDay(

        hour: int.parse(widget.initialData!["time"]!.split(":")[0]),
        minute: int.parse(widget.initialData!["time"]!.split(":")[1]),
      );
      List<String> saved = widget.initialData!["symptoms"]!.split(", ");
      selectedSymptoms = symptoms.where((s) => saved.contains(s)).toSet();
      memoController.text = widget.initialData!["memo"] ?? "";
    } else {
      selectedDate = DateTime.now();
      selectedTime = TimeOfDay.now();
    }
  }


  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF377DCE),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF202936),
            ),

            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),

            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,

              // 상단 배경
              headerBackgroundColor: const Color(0xFF377DCE),
              headerForegroundColor: Colors.white,
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              confirmButtonStyle: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),

              dayShape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF377DCE),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF202936),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              dialBackgroundColor: const Color(0xFFF0F5FC),
              dialHandColor: const Color(0xFF377DCE),
              dialTextColor: const Color(0xFF202936),
              hourMinuteColor: const Color(0xFFEAF3FF),
              hourMinuteTextColor: const Color(0xFF202936),
              dayPeriodColor: const Color(0xFFEAF3FF),
              dayPeriodTextColor: const Color(0xFF377DCE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  String getTimeSlot(TimeOfDay time) {
    final totalMinutes = time.hour * 60 + time.minute;

    if (totalMinutes < 360) return '새벽'; // 00:00 ~ 05:59
    if (totalMinutes < 720) return '오전'; // 06:00 ~ 11:59
    if (totalMinutes < 1080) return '오후'; // 12:00 ~ 17:59
    return '저녁'; // 18:00 ~ 23:59
  }


  Future<void> _saveDiaryEntry() async {
    if (selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('증상을 선택하세요.')),
      );
      return;
    }

    final DateTime fullDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final newSymptoms = symptoms
        .where((s) => selectedSymptoms.contains(s))
        .toList();

    try {
      // 저장해둔 JWT 가져오기
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인 정보가 없습니다.');
      }

      // Spring으로 보낼 데이터
      final body = jsonEncode({
        'occurredAt': fullDateTime.toIso8601String(),
        'symptoms': newSymptoms,
        'memo': memoController.text,
      });

      late http.Response response;

      // 기존 일기를 수정하는 경우
      if (widget.initialData != null &&
          widget.initialData!.containsKey('id')) {

        final id = widget.initialData!['id'];

        response = await http.put(
          Uri.parse('http://localhost:8080/api/diaries/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );
      } else {
        // 새 일기를 작성하는 경우
        response = await http.post(
          Uri.parse('http://localhost:8080/api/diaries'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );
      }

      if (response.statusCode != 200) {
        throw Exception('일기 저장 실패: ${response.statusCode}');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일기가 저장되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  @override
  void dispose() {
    memoController.dispose();
    super.dispose();
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF377DCE), size: 21),
        const SizedBox(width: 9),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF202936))),
      ],
    );
  }

  Widget _dateTimeTile({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: const Color(0xFF377DCE)),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _symptomButton(String symptom) {
    final selected = selectedSymptoms.contains(symptom);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          if (selected) {
            selectedSymptoms.remove(symptom);
          } else {
            selectedSymptoms.add(symptom);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEAF3FF)
              : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF377DCE)
                : const Color(0xFFE9EDF2),
          ),
        ),
        child: Text(
          symptom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected
                ? FontWeight.w600
                : FontWeight.w400,
            color: selected
                ? const Color(0xFF377DCE)
                : const Color(0xFF202936),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF202936)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.initialData == null ? '일기 작성' : '일기 수정',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF202936))),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(Icons.event_note_outlined, '증상 일시'),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _dateTimeTile(
                                    icon: Icons.calendar_today_outlined,
                                    text: DateFormat('yyyy.MM.dd').format(selectedDate),
                                    onTap: _selectDate,
                                  )),
                                  const SizedBox(width: 10),
                                  Expanded(child: _dateTimeTile(
                                    icon: Icons.access_time_outlined,
                                    text: selectedTime.format(context),
                                    onTap: _selectTime,
                                  )),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(Icons.favorite_border, '증상 종류'),
                              const SizedBox(height: 6),
                              const Text('해당하는 증상을 모두 선택해 주세요.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF7A8492))),
                              const SizedBox(height: 16),
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (int i = 0; i < 3; i++) ...[
                                        SizedBox(
                                          width: 90,
                                          child: _symptomButton(symptoms[i]),
                                        ),
                                        if (i < 2) const SizedBox(width: 9),
                                      ],
                                    ],
                                  ),

                                  const SizedBox(height: 9),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (int i = 3; i < 7; i++) ...[
                                        SizedBox(
                                          width: 90,
                                          child: _symptomButton(symptoms[i]),
                                        ),
                                        if (i < 6) const SizedBox(width: 9),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle(Icons.edit_note_outlined, '메모'),
                              const SizedBox(height: 14),
                              TextField(
                                controller: memoController,
                                minLines: 5,
                                maxLines: 8,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: InputDecoration(
                                  hintText: '증상이 발생한 원인이나 상태를 기록해 주세요.',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                                  filled: true,
                                  fillColor: const Color(0xFFF7F8FA),
                                  contentPadding: const EdgeInsets.all(16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF377DCE), width: 1.5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              color: const Color(0xFFF7F8FA),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveDiaryEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF377DCE),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
