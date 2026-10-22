import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lung_ts/transition_helper.dart';

import 'act_test_screen.dart';

class ActScreen extends StatefulWidget {
  const ActScreen({super.key});

  @override
  State<ActScreen> createState() => _ActScreenState();
}

class _ActScreenState extends State<ActScreen> {
  static const Color _blue = Color(0xFF377DCE);
  static const Color _dark = Color(0xFF202936);
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _grey = Color(0xFF7A8492);

  List<Map<String, dynamic>> previousResults = [];
  List<Map<String, dynamic>> allResults = [];

  bool _loading = true;

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

      if (response.statusCode != 200) {
        throw Exception('ACT 조회 실패: ${response.statusCode}');
      }

      final List<dynamic> data =
      jsonDecode(utf8.decode(response.bodyBytes));

      final results = data.map<Map<String, dynamic>>((item) {
        return {
          'score': (item['score'] as num).toInt(),
          'date': DateTime.parse(item['createdAt'].toString()),
        };
      }).toList();

      // 최신 검사부터 표시
      results.sort(
            (a, b) => (b['date'] as DateTime)
            .compareTo(a['date'] as DateTime),
      );

      if (!mounted) return;

      setState(() {
        allResults = results;
        previousResults = results.take(2).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('ACT 결과 조회 실패: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  String _scoreLabel(int score) {
    if (score >= 20) return '조절 양호';
    if (score >= 16) return '조절 미흡';
    return '조절 매우 미흡';
  }

  Color _scoreColor(int score) {
    if (score >= 20) return _blue;
    if (score >= 16) return const Color(0xFFD28A33);
    return const Color(0xFFD65C5C);
  }

  Widget _heading(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _blue, size: 21),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _dark,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
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

  Widget _buildScoreCard(Map<String, dynamic> result) {
    final DateTime date = result['date'] as DateTime;
    final int score = result['score'] as int;
    final color = _scoreColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('yyyy.MM.dd').format(date),
            style: const TextStyle(
              fontSize: 12,
              color: _grey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$score점',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _scoreLabel(score),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentResults() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(Icons.bar_chart_rounded, '최근 검사 결과'),
          const SizedBox(height: 18),

          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: _blue),
            )
          else if (previousResults.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  '아직 검사 기록이 없습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: _grey,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                for (int i = 0; i < previousResults.length; i++) ...[
                  Expanded(
                    child: _buildScoreCard(previousResults[i]),
                  ),
                  if (i < previousResults.length - 1)
                    const SizedBox(width: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildScoreGuide(
      String range,
      String description,
      Color color,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          range,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _dark,
          ),
        ),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(Icons.assignment_outlined, 'ACT 검사 안내'),
          const SizedBox(height: 16),

          const Text(
            'ACT(천식 조절 검사)는 12세 이상 천식 환자가 '
                '최근 4주 동안 천식이 얼마나 잘 조절되었는지 '
                '확인하는 검사입니다.',
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: _dark,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildScoreGuide(
                  '20~25점',
                  '잘 조절됨',
                  _blue,
                ),
                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  color: Color(0xFFE9EDF2),
                ),
                const SizedBox(height: 12),
                _buildScoreGuide(
                  '16~19점',
                  '조절 미흡',
                  const Color(0xFFD28A33),
                ),
                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  color: Color(0xFFE9EDF2),
                ),
                const SizedBox(height: 12),
                _buildScoreGuide(
                  '5~15점',
                  '조절 매우 미흡',
                  const Color(0xFFD65C5C),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            '천식이 잘 조절되지 않는 경우 약물 사용 방법과 '
                '현재 치료가 적절한지 의료진과 확인하는 것이 좋습니다.',
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: _grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showActHistory() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'ACT 검사 내역',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: allResults.isEmpty
                ? const Text(
              '검사 내역이 없습니다.',
              style: TextStyle(color: _grey),
            )
                : ListView.separated(
              shrinkWrap: true,
              itemCount: allResults.length,
              separatorBuilder: (_, __) =>
              const Divider(
                color: Color(0xFFE9EDF2),
              ),
              itemBuilder: (context, index) {
                final result = allResults[index];

                final date = result['date'] as DateTime;
                final score = result['score'] as int;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy.MM.dd').format(date),
                        style: const TextStyle(
                          fontSize: 14,
                          color: _dark,
                        ),
                      ),
                      Text(
                        '$score점',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _scoreColor(score),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                '닫기',
                style: TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startActTest() async {
    final result = await Navigator.push(
      context,
      slideFromRight(ActTestScreen()),
    );

    if (!mounted) return;

    if (result is Map<String, dynamic>) {
      await _loadActResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ACT 천식 조절 검사',
          style: TextStyle(
            color: _dark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: _dark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _showActHistory,
            tooltip: '검사 내역',
            icon: const Icon(
              Icons.history,
              color: _dark,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  12, 12, 12, 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        _buildRecentResults(),
                        const SizedBox(height: 16),
                        _buildGuideCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                12, 12, 12, 14,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _startActTest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '검사 시작',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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