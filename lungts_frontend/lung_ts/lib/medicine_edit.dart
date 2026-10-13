
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lung_ts/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicineEditScreen extends StatefulWidget {
  const MedicineEditScreen({super.key});

  @override
  State<MedicineEditScreen> createState() => _MedicineEditScreenState();
}

class _MedicineEditScreenState extends State<MedicineEditScreen> {
  List<Map<String, dynamic>> medicines = [];
  bool isLoading = true;
  String? errorMessage;
  bool isEditMenuOpen = false;

  bool isDeleting = false;
  bool isDeletingMedicines = false;
  final Set<int> selectedMedicineIds = {};

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8080/api/user-medicines'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(
          utf8.decode(response.bodyBytes),
        ) as List<dynamic>;

        if (!mounted) return;

        setState(() {
          medicines = data
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });
      } else {
        throw Exception('약 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }



  Future<void> _showAddMedicineDialog() async {
    final searchController = TextEditingController();

    List<Map<String, dynamic>> searchResults = [];
    bool searching = false;
    bool registering = false;
    bool hasSearched = false;
    String? dialogError;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> search() async {
                final keyword = searchController.text.trim();
                if (keyword.isEmpty || searching) return;

                setDialogState(() {
                  searching = true;
                  hasSearched = true;
                  dialogError = null;
                  searchResults = [];
                });

                try {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('jwt_token');

                  if (token == null || token.isEmpty) {
                    throw Exception('로그인이 필요합니다.');
                  }

                  final response = await http.get(
                    Uri.parse(
                      'http://localhost:8080/api/medicines/search-list',
                    ).replace(queryParameters: {'name': keyword}),
                    headers: {
                      'Authorization': 'Bearer $token',
                    },
                  );

                  if (response.statusCode != 200) {
                    throw Exception(
                      '검색 실패: ${response.statusCode}',
                    );
                  }

                  final data = jsonDecode(
                    utf8.decode(response.bodyBytes),
                  ) as List<dynamic>;

                  if (!dialogContext.mounted) return;

                  setDialogState(() {
                    searchResults = data
                        .map((item) =>
                    Map<String, dynamic>.from(item as Map))
                        .toList();
                  });
                } catch (e) {
                  if (!dialogContext.mounted) return;

                  setDialogState(() {
                    dialogError = '약 검색 중 오류가 발생했습니다.';
                  });

                  debugPrint('약 검색 오류: $e');
                } finally {
                  if (dialogContext.mounted) {
                    setDialogState(() => searching = false);
                  }
                }
              }

              Future<void> register(
                  Map<String, dynamic> medicine,
                  ) async {
                if (registering) return;

                setDialogState(() {
                  registering = true;
                  dialogError = null;
                });

                try {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('jwt_token');

                  if (token == null || token.isEmpty) {
                    throw Exception('로그인이 필요합니다.');
                  }

                  final response = await http.post(
                    Uri.parse(
                      'http://localhost:8080/api/user-medicines',
                    ),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'medicineCode':
                      medicine['itemSeq'].toString(),
                    }),
                  );

                  if (response.statusCode != 201) {
                    throw Exception(
                      '약 등록 실패: ${response.statusCode}',
                    );
                  }

                  if (!dialogContext.mounted) return;

                  Navigator.pop(dialogContext);

                  await _loadMedicines();

                  if (!mounted) return;

                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('약이 등록되었습니다.'),
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;

                  setDialogState(() {
                    dialogError = '약 등록에 실패했습니다.';
                  });

                  debugPrint('약 등록 오류: $e');
                } finally {
                  if (dialogContext.mounted) {
                    setDialogState(() => registering = false);
                  }
                }
              }

              return Dialog(
                backgroundColor: Colors.white,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 460,
                    maxHeight: 570,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 팝업 상단
                        Row(
                          children: [
                            const Icon(
                              Icons.medication_outlined,
                              color: Color(0xFF377DCE),
                              size: 28,
                            ),

                            const SizedBox(width: 12),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '약 추가',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '복용 중인 약을 검색해 등록하세요',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF7A8492),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        const Divider(
                          height: 1,
                          color: Color(0xFFE9EDF2),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          '약 이름 검색',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 검색창
                        TextField(
                          controller: searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => search(),
                          decoration: InputDecoration(
                            hintText: '예: 타이레놀, 벤토린',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                            ),
                            suffixIcon: IconButton(
                              onPressed: searching ? null : search,
                              icon: const Icon(
                                Icons.search,
                                color: Color(0xFF377DCE),
                                size: 24,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // 검색 결과 제목
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '검색 결과',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasSearched && !searching)
                              Text(
                                '${searchResults.length}개',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7A8492),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (searching)
                          const LinearProgressIndicator(
                            color: Color(0xFF377DCE),
                          ),

                        if (dialogError != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child: Text(
                              dialogError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        // 검색 결과 목록
                        Flexible(
                          child: !hasSearched
                              ? const Center(
                            child: Text(
                              '약 이름을 검색해 주세요.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          )
                              : !searching && searchResults.isEmpty
                              ? const Center(
                            child: Text(
                              '검색 결과가 없습니다.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          )
                              : ListView.separated(
                            shrinkWrap: true,
                            itemCount: searchResults.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final medicine =
                              searchResults[index];

                              return Material(
                                color: Colors.white,
                                child: InkWell(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                  onTap: registering
                                      ? null
                                      : () => register(medicine),
                                  child: Container(
                                    padding:
                                    const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(
                                            0xFFE9EDF2),
                                      ),
                                      borderRadius:
                                      BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration:
                                          BoxDecoration(
                                            color: const Color(
                                                0xFFEDF4FF),
                                            borderRadius:
                                            BorderRadius.circular(
                                                10),
                                          ),
                                          child: const Icon(
                                            Icons.medication_outlined,
                                            color: Color(
                                                0xFF377DCE),
                                            size: 21,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            medicine['itemName']
                                                ?.toString() ??
                                                '이름 없음',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                              FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.add_circle_outline,
                                          color: Color(0xFF377DCE),
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 하단 닫기 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: registering
                                ? null
                                : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                              const Color(0xFF5D6571),
                              side: const BorderSide(
                                color: Color(0xFFE1E5EB),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('닫기'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      // 팝업 종료 애니메이션 이후 컨트롤러 정리
      await Future<void>.delayed(
        const Duration(milliseconds: 400),
      );
      searchController.dispose();
    }
  }

  final Set<int> updatingMedicineIds = {};


  Future<void> _toggleMedicine(int medicineId, bool active) async {
    if (updatingMedicineIds.contains(medicineId)) return;

    // API 응답을 기다리지 않고 화면부터 변경
    setState(() {
      updatingMedicineIds.add(medicineId);

      final index = medicines.indexWhere(
            (medicine) => medicine['id'] == medicineId,
      );

      if (index != -1) {
        medicines[index]['active'] = active;
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인이 필요합니다.');
      }

      final action = active ? 'activate' : 'deactivate';

      final response = await http.patch(
        Uri.parse(
          'http://localhost:8080/api/user-medicines/$medicineId/$action',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204) {
        throw Exception('약 상태 변경 실패: ${response.statusCode}');
      }

      // 성공 시 전체 목록을 다시 불러오지 않음
    } catch (e) {
      if (!mounted) return;

      // 실패하면 원래 상태로 복구
      setState(() {
        final index = medicines.indexWhere(
              (medicine) => medicine['id'] == medicineId,
        );

        if (index != -1) {
          medicines[index]['active'] = !active;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상태 변경 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          updatingMedicineIds.remove(medicineId);
        });
      }
    }
  }


  void _startDeleteMode() {
    setState(() {
      isEditMenuOpen = false;
      isDeleting = true;
      selectedMedicineIds.clear();
    });
  }

  void _cancelDeleteMode() {
    setState(() {
      isDeleting = false;
      selectedMedicineIds.clear();
    });
  }

  void _toggleMedicineSelection(int id) {
    setState(() {
      if (selectedMedicineIds.contains(id)) {
        selectedMedicineIds.remove(id);
      } else {
        selectedMedicineIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedMedicines() async {
    if (selectedMedicineIds.isEmpty || isDeletingMedicines) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Color(0xFFE05A5A),
              ),
              SizedBox(width: 10),
              Text('약 삭제'),
            ],
          ),
          content: Text(
            '선택한 약 ${selectedMedicineIds.length}개를 삭제하시겠습니까?\n\n'
                '기존 복약 기록은 유지됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                '취소',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                '삭제',
                style: TextStyle(
                  color: Color(0xFFE05A5A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => isDeletingMedicines = true);

    final ids = selectedMedicineIds.toList();
    int successCount = 0;

    try {
      for (final id in ids) {
        final deleted = await _deleteMedicine(id);

        if (!mounted) return;

        if (deleted) {
          successCount++;
          selectedMedicineIds.remove(id);
        }
      }

      if (!mounted) return;

      if (selectedMedicineIds.isEmpty) {
        setState(() => isDeleting = false);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$successCount개의 약이 삭제되었습니다.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isDeletingMedicines = false);
      }
    }
  }



  Future<bool> _deleteMedicine(int medicineId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await http.delete(
        Uri.parse(
          'http://localhost:8080/api/user-medicines/$medicineId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204) {
        throw Exception('약 삭제 실패: ${response.statusCode}');
      }

      if (!mounted) return false;

      // 메인 약 목록 갱신
      setState(() {
        medicines.removeWhere(
              (medicine) => medicine['id'] == medicineId,
        );
      });

      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('약 삭제 중 오류가 발생했습니다: $e'),
        ),
      );

      return false;
    }
  }




  Future<bool> _confirmDeleteMedicine(
      int medicineId,
      String medicineName,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('약 삭제'),
          content: Text(
            '$medicineName\n\n'
                '선택한 약을 목록에서 삭제하시겠습니까?\n'
                '기존 복약 기록은 유지됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text(
                '삭제',
                style: TextStyle(
                  color: Color(0xFFE05A5A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return false;

    return await _deleteMedicine(medicineId);
  }




  Future<void> _showDeleteMedicineDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Color(0xFFE05A5A),
                  ),
                  SizedBox(width: 10),
                  Text('약 삭제'),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: medicines.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    '등록된 약이 없습니다.',
                    textAlign: TextAlign.center,
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = medicines[index];

                    return ListTile(
                      title: Text(
                        medicine['medicineName']
                            ?.toString() ??
                            '이름 없음',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () async {
                        final medicineId =
                        (medicine['id'] as num).toInt();
                        final medicineName =
                            medicine['medicineName']
                                ?.toString() ??
                                '이름 없음';

                        // 삭제 목록 팝업은 유지
                        final deleted =
                        await _confirmDeleteMedicine(
                          medicineId,
                          medicineName,
                        );

                        // 삭제 성공 시 팝업 목록 새로고침
                        if (deleted && dialogContext.mounted) {
                          setDialogState(() {});
                        }
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      },
    );
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
                    : const Color(0xFF377DCE),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        title: const Text(
          '약 정보 수정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF202936),
          ),
        ),
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
            child: isEditMenuOpen
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMenuButton(
                  icon: Icons.delete_outline,
                  title: '약 삭제',
                  isDanger: true,
                  onTap: _startDeleteMode,
                ),
                const SizedBox(height: 10),
                _buildMenuButton(
                  icon: Icons.add,
                  title: '약 추가',
                  onTap: () {
                    setState(() {
                      isEditMenuOpen = false;
                    });
                    _showAddMedicineDialog();
                  },
                ),
                const SizedBox(height: 12),
              ],
            )
                : const SizedBox.shrink(),
          ),

          FloatingActionButton(
            heroTag: 'medicineEditFab',
            backgroundColor: const Color(0xFF377DCE),
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: () {
              setState(() {
                isEditMenuOpen = !isEditMenuOpen;
              });
            },
            child: Icon(
              isEditMenuOpen
                  ? Icons.close
                  : Icons.edit_outlined,
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
                  onPressed: isDeletingMedicines
                      ? null
                      : _cancelDeleteMode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(vertical: 15),
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
                  onPressed: selectedMedicineIds.isNotEmpty &&
                      !isDeletingMedicines
                      ? _deleteSelectedMedicines
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE05A5A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isDeletingMedicines
                        ? '삭제 중...'
                        : '삭제 (${selectedMedicineIds.length})',
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : null,

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? Center(
        child: Text(errorMessage!),
      )
          : RefreshIndicator(
        onRefresh: _loadMedicines,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20, 20, 20, 100,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        color: Color(0xFF377DCE),
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Text(
                        '등록된 약',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202936),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    '복용 중인 약을 활성화하거나 비활성화할 수 있습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7A8492),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (medicines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 35,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 36,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              '등록된 약이 없습니다.',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(medicines.length, (index) {
                      final medicine = medicines[index];
                      final active =
                          medicine['active'] == true;
                      final medicineId =
                      (medicine['id'] as num).toInt();

                      return Column(
                        children: [
                          if (index > 0)
                            const Divider(
                              height: 1,
                              color: Color(0xFFE9EDF2),
                            ),

                      InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isDeleting && !isDeletingMedicines
                      ? () => _toggleMedicineSelection(medicineId)
                          : null,
                      child: Padding(
                      padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      ),
                      child: Row(
                              children: [
                                if (isDeleting) ...[
                                  Checkbox(
                                    value: selectedMedicineIds.contains(medicineId),
                                    activeColor: const Color(0xFF377DCE),
                                    onChanged: (_) => _toggleMedicineSelection(medicineId),
                                  ),
                                ] else
                                  const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medicine['medicineName']
                                            ?.toString() ??
                                            '이름 없음',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        active ? '활성화' : '비활성화',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: active
                                              ? const Color(
                                              0xFF377DCE)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                if (!isDeleting)
                                  Switch(
                                    value: active,
                                    onChanged: updatingMedicineIds.contains(medicineId)
                                        ? null
                                        : (value) {
                                      _toggleMedicine(medicineId, value);
                                    },
                                    activeTrackColor: const Color(0xFF4FC766),
                                    inactiveTrackColor: const Color(0xFF55565A),
                                    thumbColor: WidgetStateProperty.all(Colors.white),
                                    trackOutlineColor:
                                    WidgetStateProperty.all(Colors.transparent),
                                  ),
                              ],
                            ),
                          ),
                          ),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
