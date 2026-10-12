import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:lung_ts/transition_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lung_ts/app_colors.dart';

import 'act_test_screen.dart'; // 검사 화면 import

class ActScreen extends StatefulWidget {
  @override
  State<ActScreen> createState() => _ActScreenState();
}

class _ActScreenState extends State<ActScreen> {
  List<Map<String, dynamic>> previousResults = []; // 최대 2개 저장
  List<Map<String, dynamic>> allResults = [];     // 전체 검사 기록 저장

  @override
  void initState() {
    super.initState();
    _loadActResults();
  }

  Future<void> _loadActResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8080/api/act'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final results = data.map((item) {
          return {
            'score': item['score'],
            'date': DateTime.parse(item['createdAt']),
          };
        }).toList();

        if (!mounted) return;

        setState(() {
          allResults = List<Map<String, dynamic>>.from(results);

          // 메인 화면에는 최신 2개만 표시
          previousResults = allResults.take(2).toList();
        });

        print('ACT 최근 결과: $previousResults');
      } else {
        throw Exception('ACT 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('ACT 결과 조회 실패: $e');
    }
  }

  // 전체 검사 기록 팝업
  void _showActHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'ACT 검사 내역',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: allResults.isEmpty
                ? const Text('검사 내역이 없습니다.')
                : ListView.separated(
              shrinkWrap: true,
              itemCount: allResults.length,
              separatorBuilder: (context, index) =>
              const Divider(),
              itemBuilder: (context, index) {
                final result = allResults[index];

                final DateTime date = result['date'];
                final int score = result['score'];

                final String formattedDate =
                DateFormat('yyyy년 MM월 dd일').format(date);

                return Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 15),
                    ),
                    Text(
                      '$score점',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: score >= 20
                            ? Colors.indigo
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoreCard(DateTime? date, int score, Color color) {
    String formattedDate = date != null
        ? DateFormat('yyyy년 MM월 dd일').format(date)
        : '0000년 00월 00일';

    return Column(
      children: [
        Text(formattedDate, style: TextStyle(fontSize: 16, color: Colors.grey)),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$score점',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue, // 배경색 설정
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("ACT 천식 조절 검사"),
        actions: [
          IconButton(
            onPressed: _showActHistory,
            tooltip: '검사 내역',
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: Column(
        children: [
          if (previousResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 20.0, horizontal: 16.0),
              child: Container(
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
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: previousResults
                      .asMap()
                      .entries
                      .map((entry) {
                    final result = entry.value;
                    final score = result['score'];
                    final color = score >= 20 ? Colors.indigo : Colors
                        .redAccent;
                    return _buildScoreCard(result['date'], score, color);
                  })
                      .toList(),
                ),
              ),
            ),

          // 설명 컨테이너 확장
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
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
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACT 천식 조절 검사',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'ACT(천식 조절 검사)는 천식을 알고 있는 사람들(12세 이상)이 '
                            '천식을 얼마나 조절하고 있는지 평가하기 위한 검사입니다.\n'
                            '각 질문에 표시한 점수를 더하여 천식 조절 검사의 총점을 계산할 수 있습니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '• 20점 이상: 천식이 잘 조절되고 있습니다.',
                        style: TextStyle(fontSize: 14, color: Colors.indigo),
                      ),
                      Text(
                        '• 19점 미만: 천식이 잘 조절되지 않고 있습니다.\n\n'
                            '❗ 천식이 잘 조절되지 않고 있을 경우:\n'
                            '약물을 올바른 방법으로 사용하고 있는지 또는\n'
                            '현재의 흡입 수준이 적절한지 다시 확인할 필요가 있습니다.',
                        style: TextStyle(fontSize: 14, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 검사 시작 버튼
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  slideFromRight(ActTestScreen()),
                );
                if (result is Map<String, dynamic>) {
                  await _loadActResults(); // Firestore에서 최신 결과 다시 불러오기
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightBlueBg, // 배경색
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                '검사 시작',
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
