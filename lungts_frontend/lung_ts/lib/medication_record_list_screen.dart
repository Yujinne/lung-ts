import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'medication_record_screen.dart';

class MedicationRecordListScreen extends StatefulWidget {
  final DateTime selectedDate;

  const MedicationRecordListScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<MedicationRecordListScreen> createState() =>
      _MedicationRecordListScreenState();
}

class _MedicationRecordListScreenState
    extends State<MedicationRecordListScreen> {
  late DateTime selectedDate;

  static const Color _dark = Color(0xFF202936);

  List<Map<String, dynamic>> records = [];
  bool isLoading = true;
  bool isMenuOpen = false;
  bool isDeleting = false;
  bool isProcessing = false;

  Set<int> selectedRecords = <int>{};

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    loadRecords();
  }

  String get formattedDate =>
      '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일';

  String get apiDate =>
      '${selectedDate.year.toString().padLeft(4, '0')}-'
          '${selectedDate.month.toString().padLeft(2, '0')}-'
          '${selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> loadRecords() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final response = await http.get(
        // 기존 home.dart에서 사용하는 서버 주소와 동일하게 설정
        Uri.parse(
          'http://localhost:8080/api/medication-records?date=$apiDate',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('조회 실패 (${response.statusCode})');
      }

      final List<dynamic> data =
      jsonDecode(utf8.decode(response.bodyBytes));

      if (!mounted) return;

      setState(() {
        records = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
    loadRecords();
  }

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
      loadRecords();
    }
  }

  String formatDose(dynamic value) {
    final dose = (value as num).toDouble();
    return dose == dose.toInt()
        ? dose.toInt().toString()
        : dose.toString();
  }

  Future<void> deleteMedicationRecord(int recordId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final response = await http.delete(
        Uri.parse(
          'http://localhost:8080/api/medication-records/$recordId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204) {
        throw Exception('삭제 실패 (${response.statusCode})');
      }

      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      await loadRecords();
    } catch (e) {
      if (!mounted) return;
    }
  }

  Future<void> editMedicationRecord(
      Map<String, dynamic> record,
      ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationRecordScreen(
          selectedDate: selectedDate,
          record: record,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {
        isDeleting = false;
      });

      await loadRecords();
    }
  }

  Future<void> confirmDeleteMedicationRecord(
      Map<String, dynamic> record,
      ) async {
    setState(() {
      selectedRecords = {record['id'] as int};
    });

    await deleteSelectedRecords();
  }

  void showRecordOptions(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record['medicineName'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('복약 기록 수정'),
                  onTap: () async {
                    Navigator.pop(context);

                    final result = await Navigator.push<bool>(
                      this.context,
                      MaterialPageRoute(
                        builder: (context) => MedicationRecordScreen(
                          selectedDate: selectedDate,
                          record: record,
                        ),
                      ),
                    );

                    if (!mounted) return;

                    if (result == true) {
                      loadRecords();
                    }
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text('복약 기록 삭제'),
                  onTap: () async {
                    Navigator.pop(context);
                    await confirmDeleteMedicationRecord(record);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  void startDeleteMode() {
    setState(() {
      isMenuOpen = false;
      isDeleting = true;
      selectedRecords.clear();
    });
  }

  void cancelDeleteMode() {
    setState(() {
      isDeleting = false;
      selectedRecords.clear();
    });
  }

  void toggleSelection(int id) {
    setState(() {
      if (selectedRecords.contains(id)) {
        selectedRecords.remove(id);
      } else {
        selectedRecords.add(id);
      }
    });
  }

  Future<List<int>> checkLinkedRecords(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      throw Exception('로그인이 필요합니다.');
    }

    final response = await http.post(
      Uri.parse(
        'http://localhost:8080/api/medication-records/linked-check',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(ids),
    );

    if (response.statusCode != 200) {
      throw Exception('연결된 복약 기록 조회 실패 (${response.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List;

    return decoded.map((id) => (id as num).toInt()).toList();
  }

  Future<void> deleteSelectedRecords() async {
    if (selectedRecords.isEmpty || isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final ids = selectedRecords.toList();

      // 1. 연결된 폐소리 기록 확인
      final linkedIds = await checkLinkedRecords(ids);

      if (!mounted) return;

      final linkedRecords = records.where((record) {
        return linkedIds.contains(record['id']);
      }).toList();

      // 2. 삭제 확인 팝업
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '복약 기록 삭제',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '선택한 복약 기록 ${ids.length}개를 삭제하시겠습니까?',
                    style: const TextStyle(fontSize: 15),
                  ),

                  if (linkedRecords.isNotEmpty) ...[
                    const SizedBox(height: 18),

                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFE59A23),
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '폐소리 데이터와 연결된 복약 기록이 있습니다.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: linkedRecords.map((record) {
                          final takenAt = DateTime.tryParse(
                            record['takenAt']?.toString() ?? '',
                          );

                          final time = takenAt == null
                              ? '시간 없음'
                              : '${takenAt.hour.toString().padLeft(2, '0')}:'
                              '${takenAt.minute.toString().padLeft(2, '0')}';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              '• ${record['medicineName']} ($time)',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      '삭제하면 해당 복약 기록과 폐소리 데이터의 '
                          '연결이 해제됩니다.\n'
                          '폐소리 측정 결과는 삭제되지 않으며, '
                          '복약 상태는 확인 필요로 변경됩니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  '삭제',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted || confirmed != true) return;

      // 3. 여러 개 일괄 삭제 API 호출
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await http.post(
        Uri.parse(
          'http://localhost:8080/api/medication-records/batch-delete',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(ids),
      );

      if (response.statusCode != 204) {
        throw Exception('복약 기록 삭제 실패 (${response.statusCode})');
      }

      if (!mounted) return;

      setState(() {
        selectedRecords.clear();
        isDeleting = false;
      });

      await loadRecords();

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isDanger
                    ? const Color(0xFFE45252)
                    : AppColors.primaryBlue,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDanger
                      ? const Color(0xFFE45252)
                      : const Color(0xFF202936),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
      if (isMenuOpen) {
        setState(() {
          isMenuOpen = false;
        });
      }
    },
    child: Scaffold(
    backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          '복약 기록',
          style: TextStyle(
            color: _dark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFFF9FAFB),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      floatingActionButton: isDeleting
          ? null
          : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: isMenuOpen
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMenuButton(
                  icon: Icons.delete_outline,
                  title: '복약 기록 삭제',
                  isDanger: true,
                  onTap: startDeleteMode,
                ),
                const SizedBox(height: 10),
                _buildMenuButton(
                  icon: Icons.add,
                  title: '복약 기록 추가',
                  onTap: () async {
                    setState(() {
                      isMenuOpen = false;
                    });

                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicationRecordScreen(
                          selectedDate: selectedDate,
                        ),
                      ),
                    );

                    if (!mounted) return;

                    if (result == true) {
                      await loadRecords();
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            )
                : const SizedBox.shrink(),
          ),
          FloatingActionButton(
            heroTag: 'medicationEditFab',
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: const CircleBorder(),
            onPressed: toggleMenu,
            child: Icon(
              isMenuOpen ? Icons.close : Icons.edit_outlined,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 날짜 선택
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => changeDate(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  InkWell(
                    onTap: selectDate,
                    child: Row(
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => changeDate(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),

          // 복약 기록 목록
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: records.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      '해당 날짜의 복약 기록이 없습니다.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
                    : Column(
                  children: records.map((record) {
                    final takenAt = DateTime.parse(
                      record['takenAt'] as String,
                    );

                    final time =
                        '${takenAt.hour.toString().padLeft(2, '0')}:'
                        '${takenAt.minute.toString().padLeft(2, '0')}';

                    final dose = formatDose(record['dose']);
                    final unit =
                        record['doseUnit'] as String? ?? '';

                    final doseText =
                    unit == 'puff' || unit == 'mL'
                        ? '$dose $unit'
                        : '$dose$unit';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            if (isDeleting) {
                              toggleSelection(record['id'] as int);
                            } else {
                              showRecordOptions(record);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                            child: Row(
                              children: [
                                if (isDeleting) ...[
                                  Checkbox(
                                    value: selectedRecords.contains(record['id'] as int),
                                    activeColor: AppColors.primaryBlue,
                                    onChanged: (_) {
                                      toggleSelection(record['id'] as int);
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    record['medicineName'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  doseText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: isDeleting
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                  isProcessing ? null : cancelDeleteMode,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
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
                  onPressed: selectedRecords.isNotEmpty &&
                      !isProcessing
                      ? deleteSelectedRecords
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE45252),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isProcessing
                        ? '삭제 중...'
                        : '삭제 (${selectedRecords.length})',
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : null,
    ),
    );
  }
}