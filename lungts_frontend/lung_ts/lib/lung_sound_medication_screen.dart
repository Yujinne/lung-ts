import 'package:flutter/material.dart';
import 'lung_sound_medication_record_screen.dart';
import 'services/lung_sound_upload_service.dart';
import 'lung_sound_save_complete_screen.dart';

class LungSoundMedicationScreen extends StatefulWidget {
  final DateTime recordedAt;

  const LungSoundMedicationScreen({
    super.key,
    required this.recordedAt,
  });

  @override
  State<LungSoundMedicationScreen> createState() =>
      _LungSoundMedicationScreenState();
}

class _LungSoundMedicationScreenState
    extends State<LungSoundMedicationScreen> {
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color primaryBlue = Color(0xFF397DCB);

  String? selectedStatus;
  bool isUploading = false;

  Future<void> _uploadBefore() async {
    if (isUploading) return;

    setState(() {
      isUploading = true;
    });

    try {
      final result = await LungSoundUploadService.upload(
        recordedAt: widget.recordedAt,
        medicationStatus: 'BEFORE',
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LungSoundSaveCompleteScreen(
            recordedAt: widget.recordedAt,
            medicationStatus: 'BEFORE',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Widget _buildOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = selectedStatus == value;

    return InkWell(
      onTap: isUploading
          ? null
          : () {
        setState(() {
          selectedStatus = value;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEAF3FC)
              : backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryBlue
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 26,
                color: primaryBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? primaryBlue
                  : Colors.grey.shade400,
              size: 23,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '복약 상태 선택',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      20, 28, 20, 28,
                    ),
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
                        const Text(
                          '복약 상태를 선택해 주세요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          '폐소리 측정 시점을 기준으로\n'
                              '약을 복용했는지 선택해 주세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 30),

                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAF3FC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medication_outlined,
                            size: 52,
                            color: primaryBlue,
                          ),
                        ),

                        const SizedBox(height: 38),

                        _buildOption(
                          title: '복약 전',
                          subtitle: '약을 복용하기 전에 측정했어요.',
                          value: 'BEFORE',
                          icon: Icons.schedule_rounded,
                        ),

                        const SizedBox(height: 16),

                        _buildOption(
                          title: '복약 후',
                          subtitle: '약을 복용한 후에 측정했어요.',
                          value: 'AFTER',
                          icon: Icons.medication_rounded,
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          '복약 후를 선택하면 복용한 약 기록을\n'
                              '연결할 수 있어요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: selectedStatus == null || isUploading
                      ? null
                      : () {
                    if (selectedStatus == 'BEFORE') {
                      _uploadBefore();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LungSoundMedicationRecordScreen(
                                recordedAt: widget.recordedAt,
                              ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    primaryBlue.withOpacity(0.4),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isUploading
                        ? '저장 중...'
                        : selectedStatus == 'BEFORE'
                        ? '저장'
                        : '다음',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
