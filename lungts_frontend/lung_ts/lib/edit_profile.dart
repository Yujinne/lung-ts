import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password.dart';
import 'transition_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController otherDiseaseController =
  TextEditingController();

  Set<String> selectedDiseases = {};

  String userEmail = '';
  bool isLoading = true;
  String? loadError;
  String? _nameError;
  String? _diseaseError;
  String? _otherDiseaseError;

  // 수정사항이 없을 경우 메시지 출력하기 위해 확인해야 할 변수
  String originalName = '';
  Set<String> originalDiseases = {};
  String originalOtherDiseaseName = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    nameController.dispose();
    otherDiseaseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8080/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (!mounted) return;

        setState(() {
          nameController.text = data['name'] ?? '';
          userEmail = data['email'] ?? '';

          selectedDiseases =
          Set<String>.from(data['diseases'] ?? []);

          otherDiseaseController.text =
              data['otherDiseaseName'] ?? '';

          // 처음 불러온 정보 저장
          originalName = nameController.text.trim();
          originalDiseases = Set<String>.from(selectedDiseases);
          originalOtherDiseaseName =
              otherDiseaseController.text.trim();

          isLoading = false;
          loadError = null;
        });
      } else {
        throw Exception('회원 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = '회원 정보를 불러오지 못했습니다.';
      });

      debugPrint('회원 정보 조회 오류: $e');
    }
  }

  void _toggleDisease(String disease, bool? checked) {
    setState(() {
      _diseaseError = null;
      if (checked == true) {
        if (disease == 'NONE') {
          selectedDiseases.clear();
          selectedDiseases.add('NONE');
        } else {
          selectedDiseases.remove('NONE');
          selectedDiseases.add(disease);
        }
      } else {
        selectedDiseases.remove(disease);
      }

      if (!selectedDiseases.contains('OTHER')) {
        otherDiseaseController.clear();
      }
    });
  }

  bool isSaving = false;


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
              color: primaryBlue,
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
                backgroundColor: primaryBlue,
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


  Future<void> _saveUserInfo() async {
    final name = nameController.text.trim();
    final otherDiseaseName = otherDiseaseController.text.trim();


    String? nameError;
    String? diseaseError;
    String? otherDiseaseError;

    if (name.isEmpty) {
      nameError = '이름을 입력해 주세요.';
    }

    if (selectedDiseases.isEmpty) {
      diseaseError = '질환을 선택해 주세요.';
    }

    if (selectedDiseases.contains('OTHER') &&
        otherDiseaseName.isEmpty) {
      otherDiseaseError = '기타 질환명을 입력해 주세요.';
    }

    setState(() {
      _nameError = nameError;
      _diseaseError = diseaseError;
      _otherDiseaseError = otherDiseaseError;
    });

    if (nameError != null ||
        diseaseError != null ||
        otherDiseaseError != null) {
      return;
    }


    setState(() {
      isSaving = true;
    });

    try {
      // 2. JWT 가져오기
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인 정보가 없습니다.');
      }

      // 3. 회원 정보 수정 API 호출
      final response = await http.put(
        Uri.parse('http://localhost:8080/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'diseases': selectedDiseases.toList(),
          'otherDiseaseName':
          selectedDiseases.contains('OTHER')
              ? otherDiseaseName
              : null,
        }),
      );

      if (!mounted) return;

      // 4. 저장 성공
      if (response.statusCode == 200) {
        await _showResultDialog(
          '저장 완료',
          '회원 정보가 수정되었습니다.',
          success: true,
        );

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        debugPrint('회원 정보 수정 실패: ${response.body}');
        await _showResultDialog(
          '저장 실패',
          '회원 정보를 수정하지 못했습니다.\n잠시 후 다시 시도해 주세요.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('회원 정보 수정 오류: $e');

      await _showResultDialog(
        '연결 오류',
        '회원 정보를 저장하지 못했습니다.\n서버 연결 상태를 확인해 주세요.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }


  static const Color primaryBlue = Color(0xFF377DCE);
  static const Color pageBackground = Color(0xFFF9FAFB);

// 공통 카드 디자인
  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: child,
    );
  }

// 카드 제목
  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: primaryBlue, size: 23),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF202936),
          ),
        ),
      ],
    );
  }



  Future<void> _confirmSaveUserInfo() async {
    if (isSaving) return;

    final currentName = nameController.text.trim();
    final currentOtherDiseaseName =
    otherDiseaseController.text.trim();

    // 1. 저장 확인 팝업을 띄우기 전에 입력값 검사
    String? nameError;
    String? diseaseError;
    String? otherDiseaseError;

    if (currentName.isEmpty) {
      nameError = '이름을 입력해 주세요.';
    }

    if (selectedDiseases.isEmpty) {
      diseaseError = '질환을 선택해 주세요.';
    }

    if (selectedDiseases.contains('OTHER') &&
        currentOtherDiseaseName.isEmpty) {
      otherDiseaseError = '기타 질환명을 입력해 주세요.';
    }

    // 2. 입력창에 오류 표시
    setState(() {
      _nameError = nameError;
      _diseaseError = diseaseError;
      _otherDiseaseError = otherDiseaseError;
    });

    // 3. 오류가 있으면 팝업 없이 종료
    if (nameError != null ||
        diseaseError != null ||
        otherDiseaseError != null) {
      return;
    }
    // 이름 변경 여부
    final nameChanged = currentName != originalName;

    // 질환 선택 변경 여부
    final diseasesChanged =
        !selectedDiseases.containsAll(originalDiseases) ||
            !originalDiseases.containsAll(selectedDiseases);

    // 기타 질환명 변경 여부
    final otherChanged =
        selectedDiseases.contains('OTHER') &&
            currentOtherDiseaseName != originalOtherDiseaseName;

    // 변경사항이 하나도 없다면
    if (!nameChanged && !diseasesChanged && !otherChanged) {
      await _showResultDialog(
        '안내',
        '수정된 사항이 없습니다.',
      );
      return;
    }

    // 변경사항이 있을 때만 확인 팝업 표시
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
                Icons.edit_note_rounded,
                color: Color(0xFF377DCE),
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                '회원 정보 수정',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '변경한 회원 정보를 저장하시겠습니까?',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF377DCE),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed == true) {
      await _saveUserInfo();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,

      appBar: AppBar(
        backgroundColor: pageBackground,
        elevation: 0,
        title: const Text(
          '회원 정보 수정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF202936),
          ),
        ),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : loadError != null
          ? Center(
        child: Text(loadError!),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 기본 정보 카드
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    Icons.person_outline,
                    '기본 정보',
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    '이름',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      errorText: _nameError,
                      errorStyle: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      hintText: '이름을 입력하세요',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                      const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE1E5EB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE1E5EB),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                  ),


                  const SizedBox(height: 22),

                  const Text(
                    '이메일',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7A8492),
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    '이메일은 변경할 수 없습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 질환 정보 카드
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    Icons.assignment_outlined,
                    '질환 정보',
                  ),

                  const SizedBox(height: 14),

                  CheckboxListTile(
                    title: const Text('천식'),
                    value:
                    selectedDiseases.contains('ASTHMA'),
                    activeColor: primaryBlue,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity:
                    ListTileControlAffinity.leading,
                    onChanged: (value) =>
                        _toggleDisease('ASTHMA', value),
                  ),

                  CheckboxListTile(
                    title: const Text('COPD'),
                    value:
                    selectedDiseases.contains('COPD'),
                    activeColor: primaryBlue,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity:
                    ListTileControlAffinity.leading,
                    onChanged: (value) =>
                        _toggleDisease('COPD', value),
                  ),

                  CheckboxListTile(
                    title: const Text('기타'),
                    value:
                    selectedDiseases.contains('OTHER'),
                    activeColor: primaryBlue,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity:
                    ListTileControlAffinity.leading,
                    onChanged: (value) =>
                        _toggleDisease('OTHER', value),
                  ),

                  if (selectedDiseases.contains('OTHER'))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        8, 6, 8, 12,
                      ),
                      child: TextField(
                        controller: otherDiseaseController,
                        decoration: InputDecoration(
                          errorText: _otherDiseaseError,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 1.5),
                          ),
                          hintText: '기타 질환명을 입력하세요',
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (_) {
                          if (_otherDiseaseError != null) {
                            setState(() => _otherDiseaseError = null);
                          }
                        },
                      ),
                    ),

                  CheckboxListTile(
                    title: const Text('없음'),
                    value:
                    selectedDiseases.contains('NONE'),
                    activeColor: primaryBlue,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity:
                    ListTileControlAffinity.leading,
                    onChanged: (value) =>
                        _toggleDisease('NONE', value),
                  ),
                  if (_diseaseError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _diseaseError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 3. 보안 설정 카드
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    Icons.lock_outline,
                    '보안 설정',
                  ),

                  const SizedBox(height: 16),

                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          slideFromRight(
                            const ChangePasswordScreen(),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '비밀번호 변경',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 4. 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                isSaving ? null : _confirmSaveUserInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  '변경사항 저장',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}