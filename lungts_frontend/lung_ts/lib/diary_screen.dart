import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lung_ts/app_colors.dart';


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
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleBlueBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("일기 작성"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 증상일시
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.event_note, size: 20, color: Colors.black54),
                      SizedBox(width: 8),
                      Text("증상 일시", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.paleBlueBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('yyyy년 MM월 dd일').format(selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.paleBlueBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.access_time, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  selectedTime.format(context),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 증상종류
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.favorite_border, size: 20, color: Colors.black54),
                      SizedBox(width: 8),
                      Text("증상 종류", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 두 줄로 나누어 가운데 정렬
                  Center(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: List.generate(symptoms.length, (index) {
                        final symptom = symptoms[index];
                        final isSelected = selectedSymptoms.contains(symptom);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              isSelected
                                  ? selectedSymptoms.remove(symptom)
                                  : selectedSymptoms.add(symptom);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.paleBlueBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isSelected ? AppColors.primaryBlue : Colors.grey[500],
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  symptom,
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                  ),
                ],
              ),
            ),


            const SizedBox(height: 16),

            // 메모 (화면 남은 공간 꽉 채우기)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.edit_note, size: 22, color: Colors.black54),
                        SizedBox(width: 8),
                        Text("메모", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TextField(
                        controller: memoController,
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                          hintText: "증상이 발생한 원인은 무엇일까요?",
                          border: OutlineInputBorder(borderRadius: BorderRadius
                              .circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveDiaryEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightBlueBg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                    "저장", style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}