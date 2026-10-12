import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lung_ts/app_colors.dart';

class ActTestScreen extends StatefulWidget {
  @override
  State<ActTestScreen> createState() => _ActTestScreenState();
}

class _ActTestScreenState extends State<ActTestScreen> with TickerProviderStateMixin {
  int currentIndex = 0;
  List<int?> answers = List.filled(5, null);
  late final PageController _pageController;

  final List<Map<String, dynamic>> questions = [
    {
      'question': '1. 지난 4주 동안, 당신은 천식으로 인해 얼마나 많은 시간을 직장이나 학교나 집에서 평소에 했던 만큼 일하고 공부하고 활동하는데 지장을 받았습니까?',
      'options': [
        '항상 그랬다.',
        '대부분의 시간 동안 그랬다.',
        '다소의 시간 동안 그랬다.',
        '약간의 시간 동안 그랬다.',
        '전혀 그렇지 않았다.'
      ]
    },
    {
      'question': '2. 지난 4주 동안, 당신은 얼마나 자주 숨을 헐떡였거나 숨을 쉬기가 어려웠습니까?',
      'options': [
        '하루에 한 번 이상 그랬다.',
        '하루에 한 번 그랬다.',
        '일주일에 3~6번 그랬다.',
        '일주일에 1~2번 그랬다.',
        '전혀 그렇지 않았다.'
      ]
    },
    {
      'question': '3. 지난 4주 동안, 당신은 천식 증상으로 인해 얼마나 자주 밤에 잠을 깨거나 아침에 평소보다 일찍 일어났습니까?',
      'options': [
        '일주일에 4일 밤 이상을 그랬다.',
        '일주일에 2~3일 밤을 그랬다.',
        '일주일에 한 번 그랬다.',
        '한 두 번 그랬다.',
        '전혀 그렇지 않았다.'
      ]
    },
    {
      'question': '4. 지난 4주 동안, 당신은 응급약물(예: 벤토린, 베로텍 등)을 얼마나 자주 사용했습니까?',
      'options': [
        '하루에 3번 이상 사용했다.',
        '하루에 1~2번 사용했다.',
        '일주일에 2~3번 사용했다.',
        '일주일에 한 번 이하로 사용했다.',
        '전혀 사용하지 않았다.'
      ]
    },
    {
      'question': '5. 지난 4주 동안 천식을 얼마나 잘 조절했다고 평가하겠습니까?',
      'options': [
        '전혀 조절하지 못했다.',
        '잘 조절하지 못했다.',
        '다소 조절했다.',
        '잘 조절했다.',
        '완벽하게 조절했다.'
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _submitAnswers() async {
    if (answers.contains(null)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('알림'),
          content: Text('모든 문제를 선택해주세요.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('확인'))
          ],
        ),
      );
      return;
    }

    int totalScore = answers.fold(0, (prev, element) => prev + (element ?? 0));
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final response = await http.post(
        Uri.parse('http://localhost:8080/api/act'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'score': totalScore,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('ACT 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('ACT 저장 실패: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ACT 결과 저장에 실패했습니다.'),
        ),
      );

      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('검사 완료'),
        content: Text('총 점수는 $totalScore점입니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                'date': DateTime.now(),
                'score': totalScore,
              });
            },
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = questions[index];

    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['question'],
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...List.generate(5, (i) {
            return RadioListTile<int>(
              title: Text(question['options'][i]),
              value: i + 1,
              groupValue: answers[index],
              onChanged: (value) {
                setState(() {
                  answers[index] = value;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleBlueBg,
      appBar: AppBar(title: Text('ACT 검사')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) => _buildQuestionCard(index),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentIndex > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() => currentIndex--);
                      _pageController.previousPage(
                          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                    child: Text('이전'),
                  )
                else
                  SizedBox(width: 100),
                if (currentIndex < questions.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      setState(() => currentIndex++);
                      _pageController.nextPage(
                          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                    child: Text('다음 문제'),
                  )
                else
                  ElevatedButton(
                    onPressed: _submitAnswers,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightBlueBg),
                    child: Text('제출'),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
