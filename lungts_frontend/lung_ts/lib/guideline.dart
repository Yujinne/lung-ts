import 'package:flutter/material.dart';
import 'package:lung_ts/timer.dart';
import 'package:lung_ts/app_colors.dart';

class GuidelineScreen extends StatefulWidget {
  const GuidelineScreen({super.key});

  @override
  _GuidelineScreenState createState() => _GuidelineScreenState();
}

class _GuidelineScreenState extends State<GuidelineScreen> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentSensorIndex = 0;
  bool _isDeviceOn = false; // 장치 ON/OFF 상태
  late AnimationController _animationController; // 애니메이션 컨트롤러
  late Animation<double> _opacityAnimation; // 애니메이션

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // 애니메이션 지속 시간
    )..repeat(reverse: true); // 애니메이션을 반복하고 반전시킴
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController); // opacity 애니메이션
  }

  @override
  void dispose() {
    _animationController.dispose(); // 애니메이션 종료 시 리소스 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가이드라인')),
      body: PageView(
        controller: _controller,
        onPageChanged: (index) {
          setState(() {
            _currentSensorIndex = index;
          });
        },
        children: [
          _buildStep1(),
          _buildStepWithSensor(0, "1번"),
          _buildStepWithSensor(1, "2번"),
          _buildStepWithSensor(2, "3번"),
          _buildStepWithSensor(3, "4번"),
        ],
      ),
    );
  }

  // Step 1: 장치 사진과 ON 표시 확인
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/lungsound_device.png', height: 200),
          const SizedBox(height: 20),
          const Text('장치를 켠 뒤 ON 표시를 확인하세요!', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('장치 상태: '),
              Switch(
                value: _isDeviceOn,
                onChanged: (value) {
                  setState(() {
                    _isDeviceOn = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_isDeviceOn) {
                _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('장치를 켜주세요!'), duration: Duration(seconds: 1)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightBlueBg,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '다음',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2-4: 센서 깜빡임
  Widget _buildStepWithSensor(int sensorIndex, String stepNumber) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double height = constraints.maxHeight;

          // 동그라미 크기 및 위치를 화면 크기에 맞게 비율로 계산
          double circleSize = width * 0.08;  // 화면 너비의 10% 크기

          // 배경 이미지를 그대로 두고, 동그라미는 위치와 크기만 조정
          List<Positioned> sensorPositions = [
            //1번 노드
            Positioned(
              top: height * 0.31 - circleSize / 2,  // Y 위치를 비율로 설정
              left: width * 0.385 - circleSize / 2,  // X 위치를 비율로 설정
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _currentSensorIndex == 1 ? _opacityAnimation.value : 0.0,
                    child: CircleAvatar(
                      radius: circleSize / 2,
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  );
                },
              ),
            ),
            //2번 노드
            Positioned(
              top: height * 0.31 - circleSize / 2,  // Y 위치를 비율로 설정
              left: width * 0.64 - circleSize / 2,  // X 위치를 비율로 설정
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _currentSensorIndex == 2 ? _opacityAnimation.value : 0.0,
                    child: CircleAvatar(
                      radius: circleSize / 2,
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  );
                },
              ),
            ),
            //3번 노드
            Positioned(
              top: height * 0.812 - circleSize / 2,  // Y 위치를 비율로 설정
              left: width * 0.36 - circleSize / 2,  // X 위치를 비율로 설정
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _currentSensorIndex == 3 ? _opacityAnimation.value : 0.0,
                    child: CircleAvatar(
                      radius: circleSize / 2,
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  );
                },
              ),
            ),
            //4번 노드
            Positioned(
              top: height * 0.812 - circleSize / 2,  // Y 위치를 비율로 설정
              left: width * 0.645 - circleSize / 2,  // X 위치를 비율로 설정
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _currentSensorIndex == 4 ? _opacityAnimation.value : 0.0,
                    child: CircleAvatar(
                      radius: circleSize / 2,
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  );
                },
              ),
            ),
          ];

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/sensor_background.png', // 배경 이미지
                  fit: BoxFit.cover, // 이미지 크기 맞추기
                ),
              ),
              ...sensorPositions, // 동그라미 배치
              // Step number label
              Positioned(
                top: 20.0, // 위치를 화면 상단으로 지정
                left: width * 0.5 - 30, // 화면 중앙에 배치
                child: Text(
                  stepNumber,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 20.0,
                right: 20,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentSensorIndex == 4) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TimerWithGaugeScreen()),
                      );
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightBlueBg,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '다음',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              ),
            ],
          );
        },
      ),
    );
  }
}
