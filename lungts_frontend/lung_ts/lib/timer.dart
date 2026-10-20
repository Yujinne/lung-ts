
import 'dart:async';
import 'package:flutter/material.dart';
import 'lung_sound_medication_screen.dart';

class TimerWithGaugeScreen extends StatefulWidget {
  const TimerWithGaugeScreen({super.key});

  @override
  State<TimerWithGaugeScreen> createState() =>
      _TimerWithGaugeScreenState();
}

class _TimerWithGaugeScreenState extends State<TimerWithGaugeScreen> {
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color primaryBlue = Color(0xFF397DCB);

  static const int totalSeconds = 10;

  Timer? _timer;
  int _timeLeft = totalSeconds;
  bool _isMeasuring = false;
  bool _isCompleted = false;
  DateTime? _recordedAt;
  bool _isStopped = false;

  double get _progress =>
      (totalSeconds - _timeLeft) / totalSeconds;

  void _startMeasurement() {
    if (_isMeasuring || _isCompleted) return;

    _timer?.cancel();

    setState(() {
      if (!_isStopped) {
        _recordedAt = DateTime.now();
        _timeLeft = totalSeconds;
      }

      _isMeasuring = true;
      _isStopped = false;
    });

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          }

          if (_timeLeft == 0) {
            _isMeasuring = false;
            _isCompleted = true;
            timer.cancel();
          }
        });
      },
    );
  }

  void _stopMeasurement() {
    _timer?.cancel();

    setState(() {
      _isMeasuring = false;
      _isStopped = true;
    });
  }

  void _goToNextScreen() {
    if (_recordedAt == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LungSoundMedicationScreen(
          recordedAt: _recordedAt!,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildStatusIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF3FC),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _isCompleted
            ? Icons.check_rounded
            : _isMeasuring
            ? Icons.graphic_eq_rounded
            : Icons.air_rounded,
        size: 52,
        color: primaryBlue,
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: _progress,
            ),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor:
                const AlwaysStoppedAnimation<Color>(
                  primaryBlue,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isCompleted
                  ? '측정 완료'
                  : _isMeasuring
                  ? '측정 진행 중'
                  : '측정 대기 중',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            Text(
              '${(_progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.height < 750;
    final iconSize = 130.0;

    final title = _isCompleted
        ? '측정이 완료되었어요!'
        : '폐소리를 측정하고 있어요';

    final description = _isCompleted
        ? '폐소리 측정이 완료되었습니다.\n복약 정보를 선택해 주세요.'
        : '폐소리를 측정하고\n호흡 상태를 확인하고 있어요.';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '폐소리 측정',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: Column(
            children: [
              // 흰색 안내 카드
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 20 : 26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 45),

                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF3FC),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isCompleted
                            ? Icons.check_rounded
                            : Icons.graphic_eq_rounded,
                        size: iconSize * 0.55,
                        color: primaryBlue,
                      ),
                    ),

                    const SizedBox(height: 55),

                    // 안내 문구 위치 유지
                    Text(
                      _isCompleted
                          ? '측정이 정상적으로 완료되었습니다.'
                          : _isMeasuring
                          ? '남은 시간 $_timeLeft초'
                          : _isStopped
                          ? '일시정지 중 · 남은 시간 $_timeLeft초'
                          : '측정 준비가 완료되었습니다.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 35),

                    // 진행 바 영역
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildProgressBar(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // 카드 밖 측정 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isCompleted
                      ? _goToNextScreen
                      : _isMeasuring
                      ? _stopMeasurement
                      : _startMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMeasuring
                        ? const Color(0xFF6B7280)
                        : primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isCompleted
                        ? '다음'
                        : _isMeasuring
                        ? '일시정지'
                        : _isStopped
                        ? '이어서 시작'
                        : '시작',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // measurement.dart와 하단 영역 높이 통일
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
