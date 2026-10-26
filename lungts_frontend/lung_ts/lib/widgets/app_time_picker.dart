
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTimePicker {
  static const Color primaryBlue = Color(0xFF3977E8);

  static Future<TimeOfDay?> show(
      BuildContext context, {
        TimeOfDay? initialTime,
      }) {
    final initial = initialTime ?? TimeOfDay.now();

    int selectedPeriod = initial.hour < 12 ? 0 : 1;
    int selectedHour = initial.hourOfPeriod == 0
        ? 12
        : initial.hourOfPeriod;
    int selectedMinute = initial.minute;

    final periodController = FixedExtentScrollController(
      initialItem: selectedPeriod,
    );

    final hourController = FixedExtentScrollController(
      initialItem: selectedHour - 1,
    );

    final minuteController = FixedExtentScrollController(
      initialItem: selectedMinute,
    );

    return showDialog<TimeOfDay>(
      context: context,
      barrierColor: Colors.black45,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: primaryBlue,
                      size: 22,
                    ),
                    SizedBox(width: 9),
                    Text(
                      '시간 선택',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202936),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Text(
                  '복용한 시간을 선택해 주세요.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A94A6),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _buildWheel(
                        label: '오전 / 오후',
                        controller: periodController,
                        itemCount: 2,
                        textBuilder: (index) =>
                        index == 0 ? '오전' : '오후',
                        onChanged: (index) {
                          selectedPeriod = index;
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _buildWheel(
                        label: '시',
                        controller: hourController,
                        itemCount: 12,
                        textBuilder: (index) =>
                            (index + 1).toString().padLeft(2, '0'),
                        onChanged: (index) {
                          selectedHour = index + 1;
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _buildWheel(
                        label: '분',
                        controller: minuteController,
                        itemCount: 60,
                        textBuilder: (index) =>
                            index.toString().padLeft(2, '0'),
                        onChanged: (index) {
                          selectedMinute = index;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(
                            color: Color(0xFFE1E5EB),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final hour = selectedPeriod == 0
                              ? selectedHour % 12
                              : (selectedHour % 12) + 12;

                          Navigator.pop(
                            dialogContext,
                            TimeOfDay(
                              hour: hour,
                              minute: selectedMinute,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('확인'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      periodController.dispose();
      hourController.dispose();
      minuteController.dispose();
    });
  }

  static Widget _buildWheel({
    required String label,
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) textBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8A94A6),
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          height: 165,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: CupertinoPicker.builder(
            scrollController: controller,
            itemExtent: 48,
            diameterRatio: 1.8,
            squeeze: 1.1,
            useMagnifier: false,

            // 기본 선택 영역 제거
            selectionOverlay: null,

            onSelectedItemChanged: onChanged,
            childCount: itemCount,
            itemBuilder: (context, index) {
              return Center(
                child: Text(
                  textBuilder(index),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202936),
                    decoration: TextDecoration.none,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
