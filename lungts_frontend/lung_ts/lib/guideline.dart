
import 'package:flutter/material.dart';

class GuidelineScreen extends StatefulWidget {
  const GuidelineScreen({super.key});

  @override
  State<GuidelineScreen> createState() => _GuidelineScreenState();
}

class _GuidelineScreenState extends State<GuidelineScreen>
    with SingleTickerProviderStateMixin {
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color primaryBlue = Color(0xFF397DCB);

  int _currentSensorIndex = 0;

  late final AnimationController _animationController;

  // 기존 코드의 패치 위치 비율
  static const List<Offset> _sensorPositions = [
    Offset(0.428, 0.31),
    Offset(0.585, 0.31),
    Offset(0.418, 0.812),
    Offset(0.585, 0.812),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentSensorIndex == 3) {
      Navigator.pop(context);
    } else {
      setState(() {
        _currentSensorIndex++;
      });
    }
  }

  void _previousStep() {
    if (_currentSensorIndex > 0) {
      setState(() {
        _currentSensorIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 제목 및 닫기 버튼
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '패치 부착 방법',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                '표시된 위치에 패치를 부착해 주세요.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 18),

              // 현재 패치 번호
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentSensorIndex + 1}번 패치 위치',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 패치 위치 이미지
              LayoutBuilder(
                builder: (context, constraints) {
                  final imageWidth = constraints.maxWidth;
                  final imageHeight = imageWidth * 0.9;
                  final circleSize = imageWidth * 0.05;
                  final position = _sensorPositions[_currentSensorIndex];

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: imageWidth,
                      height: imageHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/sensor_background.png',
                              fit: BoxFit.contain,
                            ),
                          ),

                          Positioned(
                            left: imageWidth * position.dx -
                                circleSize / 2,
                            top: imageHeight * position.dy -
                                circleSize / 2,
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: 0.25 +
                                      _animationController.value * 0.75,
                                  child: Container(
                                    width: circleSize,
                                    height: circleSize,
                                    decoration: const BoxDecoration(
                                      color: primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 단계 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    width: index == _currentSensorIndex ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == _currentSensorIndex
                          ? primaryBlue
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );

                }),
              ),

              const SizedBox(height: 20),

              // 이전 / 다음 버튼

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentSensorIndex > 0) ...[
                    SizedBox(
                      width: 110,
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryBlue,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('이전'),
                      ),
                    ),
                    const Spacer(),
                  ],

                  SizedBox(
                    width: 110,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentSensorIndex == 3 ? '완료' : '다음',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
