import 'package:flutter/material.dart';

class LungSoundSaveCompleteScreen extends StatelessWidget {
  final DateTime recordedAt;
  final String medicationStatus;
  final String? medicineName;

  const LungSoundSaveCompleteScreen({
    super.key,
    required this.recordedAt,
    required this.medicationStatus,
    this.medicineName,
  });

  String get formattedTime {
    return '${recordedAt.year}.${recordedAt.month.toString().padLeft(2, '0')}.${recordedAt.day.toString().padLeft(2, '0')} '
        '${recordedAt.hour.toString().padLeft(2, '0')}:${recordedAt.minute.toString().padLeft(2, '0')}';
  }

  String get statusText {
    switch (medicationStatus) {
      case 'BEFORE':
        return '복약 전';
      case 'AFTER':
        return '복약 후';
      default:
        return '확인 필요';
    }
  }

  void goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202936),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Spacer(),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF3FC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 52,
                          color: Color(0xFF397DCB),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        '폐소리 저장 완료!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202936),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        '폐소리 측정 기록이\n성공적으로 저장되었어요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF6B7280),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            infoRow('측정 시간', formattedTime),

                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),

                            infoRow('복약 상태', statusText),

                            if (medicationStatus == 'AFTER' &&
                                medicineName != null) ...[
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              infoRow('연결된 약', medicineName!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => goHome(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF397DCB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '홈으로 돌아가기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}