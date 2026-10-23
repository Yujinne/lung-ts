import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MedicationRecordScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, dynamic>? record;

  const MedicationRecordScreen({
    super.key,
    required this.selectedDate,
    this.record,
  });

  @override
  State<MedicationRecordScreen> createState() =>
      _MedicationRecordScreenState();
}

class _MedicationRecordScreenState extends State<MedicationRecordScreen> {
  final TextEditingController doseController = TextEditingController();

  String? _medicineError;
  String? _doseError;

  String selectedUnit = '정';

  late DateTime takenAt;

  final List<String> units = [
    '정',
    'puff',
    'mL',
    '포',
    '기타',
  ];

  int? selectedMedicineId;

  List<Map<String, dynamic>> medicines = [];
  bool isLoadingMedicines = true;

  @override
  void initState() {
    super.initState();

    // 기본값: 메인 화면에서 선택한 날짜 + 현재 시간
    final now = DateTime.now();

    takenAt = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      now.hour,
      now.minute,
    );

    // 수정 화면이라면 기존 기록 불러오기
    if (widget.record != null) {
      final record = widget.record!;

      // 기존 약 선택
      selectedMedicineId = record['userMedicineId'] as int?;

      // 기존 복용량
      final dose = record['dose'];
      if (dose != null) {
        doseController.text = dose.toString();
      }

      // 기존 복용 단위
      selectedUnit = record['doseUnit'] as String? ?? '정';

      // 기존 복용 날짜 및 시간
      final recordedAt = record['takenAt'] as String?;
      if (recordedAt != null) {
        takenAt = DateTime.parse(recordedAt);
      }
    }

    loadMedicines();
  }

  @override
  void dispose() {
    doseController.dispose();
    super.dispose();
  }

  Future<void> selectTakenAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: takenAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ko', 'KR'),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(takenAt),
    );

    if (time == null || !mounted) return;

    setState(() {
      takenAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String get formattedTakenAt {
    final hour = takenAt.hour.toString().padLeft(2, '0');
    final minute = takenAt.minute.toString().padLeft(2, '0');

    return '${takenAt.year}년 ${takenAt.month}월 '
        '${takenAt.day}일 $hour:$minute';
  }

  bool isSaving = false;


  bool _validateInputs() {
    final doseText = doseController.text.trim();
    final dose = double.tryParse(doseText);

    String? medicineError;
    String? doseError;

    if (selectedMedicineId == null) {
      medicineError = '복용한 약을 선택해 주세요.';
    }

    if (doseText.isEmpty) {
      doseError = '복용량을 입력해 주세요.';
    } else if (dose == null || !dose.isFinite || dose <= 0) {
      doseError = '올바른 복용량을 입력해 주세요.';
    }

    setState(() {
      _medicineError = medicineError;
      _doseError = doseError;
    });

    return medicineError == null && doseError == null;
  }


  Future<void> confirmSaveRecord() async {
    if (isSaving || isLoadingMedicines) return;

    // 입력 오류가 있으면 확인 팝업을 띄우지 않음
    if (!_validateInputs()) return;

    // 신규 등록은 기존처럼 바로 저장
    if (widget.record == null) {
      await saveRecord();
      return;
    }


    // 수정일 때만 확인 팝업 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: AppColors.primaryBlue,
                size: 44,
              ),
              SizedBox(height: 12),
              Text(
                '복약 기록 수정',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '복약 기록을 수정하시겠습니까?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(
                        color: Color(0xFFE1E5EB),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                    child: const Text('수정'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );


    if (!mounted || confirmed != true) return;

    await saveRecord();
  }


  Future<void> _showResultDialog(
      String title,
      String message, {
        bool success = false,
      }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Icon(
              success
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              color: AppColors.primaryBlue,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> saveRecord() async {
    final dose = double.tryParse(doseController.text.trim());

    if (!_validateInputs()) return;

    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인 정보가 없습니다.');
      }

      // LocalDateTime 형식: yyyy-MM-ddTHH:mm:ss
      final takenAtString =
          '${takenAt.year.toString().padLeft(4, '0')}-'
          '${takenAt.month.toString().padLeft(2, '0')}-'
          '${takenAt.day.toString().padLeft(2, '0')}T'
          '${takenAt.hour.toString().padLeft(2, '0')}:'
          '${takenAt.minute.toString().padLeft(2, '0')}:00';

      final isEditing = widget.record != null;

      final body = jsonEncode({
        'userMedicineId': selectedMedicineId,
        'takenAt': takenAtString,
        'dose': dose,
        'doseUnit': selectedUnit,
      });

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      };

      final http.Response response;

      if (isEditing) {
        // 기존 복약 기록 수정
        final recordId = widget.record!['id'];

        response = await http.put(
          Uri.parse(
            'http://localhost:8080/api/medication-records/$recordId',
          ),
          headers: headers,
          body: body,
        );
      } else {
        // 새로운 복약 기록 등록
        response = await http.post(
          Uri.parse(
            'http://localhost:8080/api/medication-records',
          ),
          headers: headers,
          body: body,
        );
      }

      final success = isEditing
          ? response.statusCode == 200
          : response.statusCode == 201;

      if (!success) {
        throw Exception(
          '복약 기록 ${isEditing ? '수정' : '저장'} 실패 '
              '(${response.statusCode}): '
              '${utf8.decode(response.bodyBytes)}',
        );
      }

      if (!mounted) return;

      await _showResultDialog(
        widget.record == null ? '저장 완료' : '수정 완료',
        widget.record == null
            ? '복약 기록이 저장되었습니다.'
            : '복약 기록이 수정되었습니다.',
        success: true,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('복약 기록 저장 오류: $e');

      if (!mounted) return;

      await _showResultDialog(
        '저장 실패',
        '복약 기록을 저장하지 못했습니다.\n잠시 후 다시 시도해 주세요.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> loadMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8080/api/user-medicines'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('약 목록 조회 실패: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

      if (!mounted) return;

      setState(() {
        medicines = data
            .where((item) => item['active'] == true)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        isLoadingMedicines = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingMedicines = false;
      });

      debugPrint('약 목록 조회 오류: $e');

      await _showResultDialog(
        '조회 실패',
        '복용 중인 약 목록을 불러오지 못했습니다.\n잠시 후 다시 시도해 주세요.',
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    IconData? icon,
    String? error,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(
        icon,
        color: AppColors.primaryBlue,
        size: 20,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5EAF0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primaryBlue,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      errorText: error,
      errorStyle: const TextStyle(fontSize: 12),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          widget.record == null ? '복약 기록하기' : '복약 기록 수정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFFF9FAFB),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '복용한 약',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (isLoadingMedicines)
                const Center(child: CircularProgressIndicator())
              else

                DropdownButtonFormField<int>(
                  value: selectedMedicineId,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primaryBlue,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  menuMaxHeight: 300,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF202936),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _fieldDecoration(
                    hint: '복용한 약을 선택해 주세요',
                    icon: Icons.medication_outlined,
                    error: _medicineError,
                  ),
                  items: medicines.map((medicine) {
                    return DropdownMenuItem<int>(
                      value: medicine['id'] as int,
                      child: Text(
                        medicine['medicineName'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMedicineId = value;
                      _medicineError = null;
                    });
                  },
                ),


              const SizedBox(height: 24),

              const Text(
                '복용량',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child:
                    TextField(
                      controller: doseController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF202936),
                      ),
                      onChanged: (_) {
                        if (_doseError != null) {
                          setState(() => _doseError = null);
                        }
                      },
                      decoration: _fieldDecoration(
                        hint: '예: 1',
                        icon: Icons.edit_outlined,
                        error: _doseError,
                      ),
                    ),

                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child:
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF202936),
                      ),
                      decoration: _fieldDecoration(
                        hint: '단위',
                      ),
                      items: units.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedUnit = value;
                          });
                        }
                      },
                    ),

                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                '복용 시간',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),


              InkWell(
                onTap: selectTakenAt,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: _fieldDecoration(
                    hint: '',
                    icon: Icons.calendar_month_outlined,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formattedTakenAt,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF202936),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),


              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : confirmSaveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.record == null ? '기록 저장하기' : '수정 완료',
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