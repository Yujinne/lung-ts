import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ActTestScreen extends StatefulWidget {
  const ActTestScreen({super.key});

  @override
  State<ActTestScreen> createState() => _ActTestScreenState();
}

class _ActTestScreenState extends State<ActTestScreen> {
  static const Color _blue = Color(0xFF377DCE);
  static const Color _dark = Color(0xFF202936);
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _grey = Color(0xFF7A8492);

  int currentIndex = 0;
  final List<int?> answers = List<int?>.filled(5, null);

  late final PageController _pageController;
  bool _submitting = false;

  final List<Map<String, dynamic>> questions = [
    {
      'question':
      '지난 4주 동안, 당신은 천식으로 인해 얼마나 많은 시간을 직장이나 학교나 집에서 평소에 했던 만큼 일하고 공부하고 활동하는데 지장을 받았습니까?',
      'options': [
        '항상 그랬다.',
        '대부분의 시간 동안 그랬다.',
        '다소의 시간 동안 그랬다.',
        '약간의 시간 동안 그랬다.',
        '전혀 그렇지 않았다.',
      ],
    },
    {
      'question':
      '지난 4주 동안, 당신은 얼마나 자주 숨을 헐떡였거나 숨을 쉬기가 어려웠습니까?',
      'options': [
        '하루에 한 번 이상 그랬다.',
        '하루에 한 번 그랬다.',
        '일주일에 3~6번 그랬다.',
        '일주일에 1~2번 그랬다.',
        '전혀 그렇지 않았다.',
      ],
    },
    {
      'question':
      '지난 4주 동안, 당신은 천식 증상으로 인해 얼마나 자주 밤에 잠을 깨거나 아침에 평소보다 일찍 일어났습니까?',
      'options': [
        '일주일에 4일 밤 이상을 그랬다.',
        '일주일에 2~3일 밤을 그랬다.',
        '일주일에 한 번 그랬다.',
        '한 두 번 그랬다.',
        '전혀 그렇지 않았다.',
      ],
    },
    {
      'question':
      '지난 4주 동안, 당신은 응급약물(예: 벤토린, 베로텍 등)을 얼마나 자주 사용했습니까?',
      'options': [
        '하루에 3번 이상 사용했다.',
        '하루에 1~2번 사용했다.',
        '일주일에 2~3번 사용했다.',
        '일주일에 한 번 이하로 사용했다.',
        '전혀 사용하지 않았다.',
      ],
    },
    {
      'question':
      '지난 4주 동안 천식을 얼마나 잘 조절했다고 평가하겠습니까?',
      'options': [
        '전혀 조절하지 못했다.',
        '잘 조절하지 못했다.',
        '다소 조절했다.',
        '잘 조절했다.',
        '완벽하게 조절했다.',
      ],
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

  void _nextQuestion() {
    if (answers[currentIndex] == null) {
      return;
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
      });

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });

      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }


  Future<void> _showWarningDialog(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: _blue,
                size: 44,
              ),
              SizedBox(height: 12),
              Text(
                '안내',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: _dark,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: _dark,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _submitAnswers() async {
    if (_submitting) return;

    if (answers.contains(null)) {
      if (answers.contains(null)) {
        await _showWarningDialog(
          '모든 문제를 선택해 주세요.',
        );
        return;
      }
      return;
    }

    final int totalScore = answers.fold<int>(
      0,
          (sum, answer) => sum + (answer ?? 0),
    );

    setState(() {
      _submitting = true;
    });

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

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception('ACT 저장 실패: ${response.statusCode}');
      }

      if (!mounted) return;

      setState(() {
        _submitting = false;
      });

      _showResultDialog(totalScore);
    } catch (e) {
      debugPrint('ACT 저장 실패: $e');

      if (!mounted) return;

      setState(() {
        _submitting = false;
      });
    }
  }

  String _scoreLabel(int score) {
    if (score >= 20) return '천식 조절 양호';
    if (score >= 16) return '천식 조절 미흡';
    return '천식 조절 매우 미흡';
  }

  Color _scoreColor(int score) {
    if (score >= 20) return _blue;
    if (score >= 16) return const Color(0xFFD28A33);
    return const Color(0xFFD65C5C);
  }

  void _showResultDialog(int totalScore) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            '검사 완료',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Icon(
                Icons.check_circle_outline_rounded,
                color: _blue,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '$totalScore점',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: _scoreColor(totalScore),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _scoreLabel(totalScore),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _scoreColor(totalScore),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '검사 결과가 저장되었습니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: _grey,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, {
                    'date': DateTime.now(),
                    'score': totalScore,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOption(int questionIndex, int optionIndex) {
    final bool selected =
        answers[questionIndex] == optionIndex + 1;

    final List<dynamic> options =
    questions[questionIndex]['options'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            answers[questionIndex] = optionIndex + 1;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEAF3FF)
                : _background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? _blue
                  : const Color(0xFFE9EDF2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _blue : Colors.white,
                  border: Border.all(
                    color: selected
                        ? _blue
                        : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 15,
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  options[optionIndex].toString(),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: selected ? _blue : _dark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final String question =
    questions[index]['question'].toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QUESTION ${index + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _blue,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              question,
              style: const TextStyle(
                fontSize: 17,
                height: 1.55,
                fontWeight: FontWeight.w700,
                color: _dark,
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              5,
                  (i) => _buildOption(index, i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final double progress =
        (currentIndex + 1) / questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '검사 진행률',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _dark,
              ),
            ),
            Text(
              '${currentIndex + 1} / ${questions.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0,
            end: progress,
          ),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
          builder: (context, animatedProgress, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: animatedProgress,
                minHeight: 8,
                backgroundColor: const Color(0xFFF9FAFB),
                valueColor: const AlwaysStoppedAnimation<Color>(_blue),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    final bool isLast =
        currentIndex == questions.length - 1;

    return Row(
      children: [
        if (currentIndex > 0) ...[
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _submitting
                    ? null
                    : _previousQuestion,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _dark,
                  side: const BorderSide(
                    color: Color(0xFFDDE4EC),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '이전',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting
                  ? null
                  : isLast
                  ? _submitAnswers
                  : _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                isLast ? '제출하기' : '다음 문제',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
          'ACT 검사',
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12, 16, 12, 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(maxWidth: 600),
                  child: _buildProgress(),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(maxWidth: 600),
                  child: PageView.builder(
                    controller: _pageController,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        child: _buildQuestionCard(index),
                      );
                    },
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
                  constraints:
                  const BoxConstraints(maxWidth: 600),
                  child: _buildBottomButtons(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}