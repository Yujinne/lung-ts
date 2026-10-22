import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'medicine_registration_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final Set<String> selectedDiseases = {};
  final otherDiseaseController = TextEditingController();

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    otherDiseaseController.dispose();
    super.dispose();
  }


  Future<void> _showMedicineLaterDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.medication_outlined,
                size: 42,
                color: Color(0xFF377DCE),
              ),
              SizedBox(height: 16),
              Text(
                '약은 나중에도 등록할 수 있어요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202936),
                ),
              ),
            ],
          ),
          content: const Text(
            '마이페이지 → 약 정보 수정에서\n'
                '언제든지 복용 중인 약을 추가할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9FAFB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _signUp() async {
    final name = userNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    final otherDisease = otherDiseaseController.text.trim();

    // 질환을 하나 이상 선택했는지 확인
    if (selectedDiseases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('질환을 선택해 주세요. 해당 사항이 없으면 "없음"을 선택해 주세요.'),
        ),
      );
      return;
    }

    // 기타 선택 시 질환명 필수 입력
    if (selectedDiseases.contains('OTHER') && otherDisease.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기타 질환명을 입력해 주세요.'),
        ),
      );
      return;
    }

    // 1. 입력값 확인
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이름, 이메일, 비밀번호를 모두 입력해 주세요.'),
        ),
      );
      return;
    }

    // 2. 백엔드 회원가입 조건 사전 검증
    try {
      final validateResponse = await http.post(
        Uri.parse('http://localhost:8080/api/auth/signup/validate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'diseases': selectedDiseases.toList(),
          'otherDiseaseName': selectedDiseases.contains('OTHER')
              ? otherDisease
              : null,
        }),
      );

      if (!mounted) return;

      // 조건을 통과하지 못하면 오류 표시 후 종료
      if (validateResponse.statusCode != 200) {
        final message = utf8.decode(validateResponse.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty
                ? message
                : '회원가입 정보를 확인해 주세요.'),
          ),
        );

        return;
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('회원가입 사전 검증 오류: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서버에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요.'),
        ),
      );

      return;
    }

    // 2. 회원가입 전에 팝업 표시
    final registerMedicine = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          title: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                ),
              ),
              const Icon(
                Icons.medication_outlined,
                size: 48,
                color: Color(0xFF3678C8),
              ),
              const SizedBox(height: 16),
              const Text(
                '현재 복용 중인 약이 있으신가요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '복용 중인 약을 등록하면\n복약 기록을 편리하게 관리할 수 있어요.',
            textAlign: TextAlign.center,
          ),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9FAFB),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('네, 약을 등록할게요'),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext, false);
                    await _showMedicineLaterDialog();
                  },
                  child: const Text('아니요, 다음에 할게요'),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    // X를 누르면 회원가입하지 않고 입력 화면 유지
    if (registerMedicine == null) return;

    if (registerMedicine == false) {
      await _showMedicineLaterDialog();
      if (!mounted) return;
    }

    // 3. 팝업에서 선택한 후 실제 회원가입
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'diseases': selectedDiseases.toList(),
          'otherDiseaseName': selectedDiseases.contains('OTHER')
              ? otherDisease
              : null,
        }),
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입 실패 (${response.statusCode})'),
          ),
        );
        return;
      }

      // 4. 자동 로그인
      final loginResponse = await http.post(
        Uri.parse('http://localhost:8080/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (!mounted) return;

      if (loginResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입은 완료됐지만 자동 로그인에 실패했습니다.'),
          ),
        );
        return;
      }

      final token = loginResponse.body.trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);

      if (token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 토큰이 없습니다.')),
        );
        return;
      }

      // 5. 약 등록 여부에 따라 이동
      if (registerMedicine == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineRegistrationScreen(token: token),
          ),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('회원가입 처리 오류: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원가입 처리 중 오류가 발생했습니다.'),
        ),
      );
    }


  }

  Widget buildDiseaseSelector() {
    final hasNone = selectedDiseases.contains('NONE');
    final hasDisease = selectedDiseases.any((d) => d != 'NONE');

    Widget diseaseOption(String value, String label) {
      final selected = selectedDiseases.contains(value);
      final disabled = value == 'NONE' ? hasDisease : hasNone;

      return CheckboxListTile(
        title: Text(
          label,
          style: TextStyle(
            color: disabled ? Colors.grey : Colors.black87,
          ),
        ),
        value: selected,
        onChanged: disabled
            ? null
            : (checked) {
          setState(() {
            if (checked == true) {
              selectedDiseases.add(value);
            } else {
              selectedDiseases.remove(value);

              if (value == 'OTHER') {
                otherDiseaseController.clear();
              }
            }
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '질환 선택',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        diseaseOption('ASTHMA', '천식'),
        diseaseOption('COPD', 'COPD'),
        diseaseOption('OTHER', '기타'),

        if (selectedDiseases.contains('OTHER'))
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 8,
              bottom: 12,
            ),
            child: TextField(
              controller: otherDiseaseController,
              decoration: const InputDecoration(
                labelText: '질환명',
                hintText: '질환명을 입력해 주세요',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),

        diseaseOption('NONE', '없음'),
        const SizedBox(height: 4),
        const Text(
          '질환 정보는 마이페이지에서도 변경할 수 있습니다.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 22),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF377DCE), width: 1.5),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '회원가입',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202936),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '정보를 입력하고 계정을 만들어 주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Color(0xFF7A8492)),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: userNameController,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                        decoration: _inputDecoration('이름', Icons.person_outline),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                        decoration: _inputDecoration('이메일', Icons.mail_outline),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: _signUp,
                        decoration: _inputDecoration('비밀번호', Icons.lock_outline),
                      ),
                      const SizedBox(height: 26),
                      const Divider(color: Color(0xFFE9EDF2), height: 1),
                      const SizedBox(height: 20),
                      buildDiseaseSelector(),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF377DCE),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '회원가입',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
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
