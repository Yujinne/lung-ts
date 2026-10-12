import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password.dart';

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

  Future<void> _saveUserInfo() async {
    final name = nameController.text.trim();
    final otherDiseaseName = otherDiseaseController.text.trim();

    // 1. 입력값 검증
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해 주세요.')),
      );
      return;
    }

    if (selectedDiseases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('질환을 선택해 주세요.')),
      );
      return;
    }

    if (selectedDiseases.contains('OTHER') &&
        otherDiseaseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기타 질환명을 입력해 주세요.')),
      );
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
        Navigator.pop(context, true);
      } else {
        debugPrint('회원 정보 수정 실패: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원 정보 수정 실패 (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('회원 정보 수정 오류: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원 정보를 저장하지 못했습니다.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 정보 수정'),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이름 수정
            const Text(
              '이름',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '이름을 입력하세요',
              ),
            ),

            const SizedBox(height: 24),

            // 이메일 (수정 불가)
            const Text(
              '이메일',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: userEmail),
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),

            const SizedBox(height: 24),

            // 질환 선택
            const Text(
              '질환 정보',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            CheckboxListTile(
              title: const Text('천식'),
              value: selectedDiseases.contains('ASTHMA'),
              onChanged: (value) =>
                  _toggleDisease('ASTHMA', value),
            ),
            CheckboxListTile(
              title: const Text('COPD'),
              value: selectedDiseases.contains('COPD'),
              onChanged: (value) =>
                  _toggleDisease('COPD', value),
            ),
            CheckboxListTile(
              title: const Text('기타'),
              value: selectedDiseases.contains('OTHER'),
              onChanged: (value) =>
                  _toggleDisease('OTHER', value),
            ),

            if (selectedDiseases.contains('OTHER'))
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: otherDiseaseController,
                  decoration: const InputDecoration(
                    labelText: '기타 질환명',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

            CheckboxListTile(
              title: const Text('없음'),
              value: selectedDiseases.contains('NONE'),
              onChanged: (value) =>
                  _toggleDisease('NONE', value),
            ),

            const SizedBox(height: 24),

            // 저장 버튼 (다음 단계에서 연결)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveUserInfo,
                child: Text(isSaving ? '저장 중...' : '변경사항 저장'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const ChangePasswordScreen(),
                    ),
                  );
                },
                child: const Text('비밀번호 변경'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}