import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lung_ts/app_colors.dart';
import 'services/lung_sound_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medication_record_screen.dart';
import 'lung_sound_save_complete_screen.dart';

class LungSoundMedicationRecordScreen extends StatefulWidget {
  final DateTime recordedAt;

  const LungSoundMedicationRecordScreen({
    super.key,
    required this.recordedAt,
  });

  @override
  State<LungSoundMedicationRecordScreen> createState() =>
      _LungSoundMedicationRecordScreenState();
}

class _LungSoundMedicationRecordScreenState
    extends State<LungSoundMedicationRecordScreen> {
  List<Map<String, dynamic>> records = [];
  Set<int> selectedRecordIds = {};
  bool isLoading = true;
  String? errorMessage;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final date = widget.recordedAt.toIso8601String().substring(0, 10);

      final uri = Uri.parse(
        'http://localhost:8080/api/medication-records',
      ).replace(queryParameters: {'date': date});

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('복약 기록 조회 실패: ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List;

      final loaded = decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        records = loaded;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _uploadAfter() async {
    if (isUploading || selectedRecordIds.isEmpty) return;

    setState(() {
      isUploading = true;
    });

    try {
      await LungSoundUploadService.upload(
        recordedAt: widget.recordedAt,
        medicationStatus: 'AFTER',
        medicationRecordIds: selectedRecordIds.toList(),
      );

      if (!mounted) return;

      final selectedNames = records
          .where((record) =>
          selectedRecordIds.contains(record['id']))
          .map((record) =>
      record['medicineName']?.toString() ?? '약 이름 없음')
          .join(', ');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LungSoundSaveCompleteScreen(
            recordedAt: widget.recordedAt,
            medicationStatus: 'AFTER',
            medicineName: selectedNames,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Future<void> _refreshRecords() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      selectedRecordIds.clear();
    });

    await _loadRecords();
  }

  Future<void> _openAddMedicationRecord() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationRecordScreen(
          selectedDate: widget.recordedAt,
          measurementTime: widget.recordedAt,
        ),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      await _refreshRecords();
    }
  }

  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color primaryBlue = Color(0xFF397DCB);

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final id = record['id'] as int;
    final isSelected = selectedRecordIds.contains(id);

    final takenAt = DateTime.tryParse(
      record['takenAt']?.toString() ?? '',
    );

    final timeText = takenAt == null
        ? '시간 정보 없음'
        : DateFormat('HH:mm').format(takenAt);

    final medicineName =
        record['medicineName']?.toString() ?? '약 이름 없음';

    final dose = record['dose']?.toString() ?? '';
    final doseUnit = record['doseUnit']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isUploading
            ? null
            : () {
          setState(() {
            if (selectedRecordIds.contains(id)) {
              selectedRecordIds.remove(id);
            } else {
              selectedRecordIds.add(id);
            }
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEAF3FC)
                : backgroundColor,
            borderRadius: BorderRadius.circular(14),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: primaryBlue,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicineName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$timeText  ·  $dose $doseUnit',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '복약 기록 선택',
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                        '복용한 약을 선택해 주세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '폐소리 측정 전에 복용한 약을\n'
                            '목록에서 선택해 주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Expanded(
                        child: isLoading
                            ? const Center(
                          child: CircularProgressIndicator(
                            color: primaryBlue,
                          ),
                        )
                            : errorMessage != null
                            ? Center(
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                        )
                            : records.isEmpty
                            ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                size: 48,
                                color: Colors.black26,
                              ),
                              SizedBox(height: 12),
                              Text(
                                '복약 기록이 없어요.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '아래에서 복약 기록을 추가해 주세요.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                            : RefreshIndicator(
                          color: primaryBlue,
                          onRefresh: _refreshRecords,
                          child: ListView.builder(
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              return _buildRecordCard(
                                records[index],
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        '복약 기록을 깜빡하셨나요?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: isUploading
                            ? null
                            : _openAddMedicationRecord,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          size: 19,
                        ),
                        label: const Text(
                          '복약 기록 추가',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: selectedRecordIds.isEmpty || isUploading
                      ? null
                      : _uploadAfter,
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
                    isUploading ? '저장 중...' : '저장',
                    style: const TextStyle(
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
    );
  }
}
