import 'package:flutter/material.dart';
import 'measurement.dart';
import 'package:lung_ts/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimerWithGaugeScreen extends StatefulWidget {
  const TimerWithGaugeScreen({super.key});

  @override
  _TimerWithGaugeScreenState createState() => _TimerWithGaugeScreenState();
}

class _TimerWithGaugeScreenState extends State<TimerWithGaugeScreen> {
  int _timeLeft = 10;
  double _progress = 0.0;
  late final ValueNotifier<int> _timerNotifier;
  bool _isMeasuring = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _timerNotifier = ValueNotifier<int>(_timeLeft);
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_timeLeft > 0 && _isMeasuring) {
        setState(() {
          _timeLeft--;
          _progress = (10 - _timeLeft) / 10.0;
        });
        _timerNotifier.value = _timeLeft;
        _startTimer();
      } else if (_timeLeft == 0) {
        setState(() {
          _isCompleted = true;
        });

        _saveVoiceLog();
      }
    });
  }

  void _saveVoiceLog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final dateKey = "${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}";
    final timeKey = "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}";

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lung_sound_result')
        .doc(); // 자동 생성 ID

    await docRef.set({
      'date': dateKey,
      'time': timeKey,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('✅ Firestore에 저장 완료!');
  }


  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightBlueBg,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.paleBlueBg,
      appBar: AppBar(
        title: const Text('음성 측정 시작'),
        backgroundColor: AppColors.lightBlueBg,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // ⬅ 핵심 포인트!
            children: [
              if (!_isMeasuring && !_isCompleted)
                const Text(
                  '측정 시작 버튼을 눌러주세요',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 15),
              if (!_isCompleted)
                Transform.scale(
                  scale: 2.5,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 15.0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.lightBlueBg,
                    ),
                  ),
                ),
              if (!_isCompleted)
                ValueListenableBuilder<int>(
                  valueListenable: _timerNotifier,
                  builder: (context, value, child) {
                    return Text(
                      '$value초',
                      style: const TextStyle(fontSize: 24),
                    );
                  },
                ),
              const SizedBox(height: 10),
              if (!_isMeasuring && !_isCompleted)
                _buildButton('측정 시작', () {
                  setState(() {
                    _isMeasuring = true;
                  });
                  _startTimer();
                }),
              if (_isMeasuring && !_isCompleted)
                _buildButton('측정 중', () {}),
              if (_isCompleted) ...[
                Image.asset('assets/complete.png', height: 150),
                const Text(
                  '측정이 완료되었습니다!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                _buildButton('종료', () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MeasurementScreen()),
                        (route) => route.settings.name == '/guideline',
                  );
                }),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
