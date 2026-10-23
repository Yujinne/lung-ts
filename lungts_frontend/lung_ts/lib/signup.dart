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
  final confirmPasswordController = TextEditingController();
  final Set<String> selectedDiseases = {};
  final otherDiseaseController = TextEditingController();
  final confirmPasswordFocusNode = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _diseaseError;
  String? _otherDiseaseError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();

    confirmPasswordFocusNode.addListener(() {
      if (!confirmPasswordFocusNode.hasFocus) {
        _validatePasswordMatch();
      }
    });
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    otherDiseaseController.dispose();
    confirmPasswordController.dispose();
    confirmPasswordFocusNode.dispose();
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

  void _validatePasswordMatch() {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // 비밀번호 확인란이 비어 있으면 불일치 검사하지 않음
    if (confirmPassword.isEmpty) return;

    final isMismatch = password != confirmPassword;

    setState(() {
      _passwordError = null;
      _confirmPasswordError = isMismatch
          ? '비밀번호가 일치하지 않습니다.'
          : null;
    });
  }

  void _onPasswordChanged(String value) {
    // 수정 중에는 기존 불일치 오류 제거
    if (_confirmPasswordError != null ||
        _passwordError != null) {
      setState(() {
        _passwordError = null;
        _confirmPasswordError = null;
      });
    }
  }


  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 44,
            ),
            SizedBox(height: 12),
            Text(
              '오류 발생',
              style: TextStyle(
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
                backgroundColor: const Color(0xFF377DCE),
                foregroundColor: Colors.white,
              ),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _signUp() async {
    final name = userNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    final otherDisease = otherDiseaseController.text.trim();


    // 입력값 오류 초기화 및 검사
    String? nameError;
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;
    String? diseaseError;
    String? otherDiseaseError;

    if (name.isEmpty) {
      nameError = '이름을 입력해 주세요.';
    }

    if (email.isEmpty) {
      emailError = '이메일을 입력해 주세요.';
    } else if (!RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(email)) {
      emailError = '올바른 이메일 형식을 입력해 주세요.';
    }

    if (password.isEmpty) {
      passwordError = '비밀번호를 입력해 주세요.';
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordError = '비밀번호를 다시 입력해 주세요.';
    }

    if (password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        password != confirmPassword) {
      confirmPasswordError = '비밀번호가 일치하지 않습니다.';
    }

    if (selectedDiseases.isEmpty) {
      diseaseError = '질환을 선택해 주세요. 해당 사항이 없으면 "없음"을 선택해 주세요.';
    }

    if (selectedDiseases.contains('OTHER') &&
        otherDisease.isEmpty) {
      otherDiseaseError = '기타 질환명을 입력해 주세요.';
    }

    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
      _diseaseError = diseaseError;
      _otherDiseaseError = otherDiseaseError;
    });

    // 입력 오류가 있으면 회원가입 진행 중단
    if (nameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null ||
        diseaseError != null ||
        otherDiseaseError != null) {
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


      if (validateResponse.statusCode != 200) {
        String message = '회원가입 정보를 확인해 주세요.';

        try {
          final data = jsonDecode(
            utf8.decode(validateResponse.bodyBytes),
          );

          if (data is Map && data['message'] is String) {
            message = data['message'];
          }
        } catch (e) {
          debugPrint('회원가입 오류 메시지 파싱 실패: $e');
        }

        setState(() {
          if (message.contains('이메일')) {
            _emailError = message;
          } else if (message.contains('비밀번호')) {
            _passwordError = message;
          } else if (message.contains('이름')) {
            _nameError = message;
          } else if (message.contains('질환')) {
            _diseaseError = message;
          } else {
            _emailError = message;
          }
        });

        return;
      }

    } catch (e) {
      if (!mounted) return;

      debugPrint('회원가입 사전 검증 오류: $e');

      await _showErrorDialog(
        '서버에 연결할 수 없습니다.\n잠시 후 다시 시도해 주세요.',
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
                      backgroundColor: const Color(0xFF3678C8),
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
        await _showErrorDialog(
          '회원가입에 실패했습니다.\n잠시 후 다시 시도해 주세요.',
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
        await _showErrorDialog(
          '회원가입은 완료됐지만 자동 로그인에 실패했습니다.\n로그인 화면에서 다시 로그인해 주세요.',
        );
        return;
      }

      final token = loginResponse.body.trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);

      if (token.isEmpty) {
        await _showErrorDialog(
          '로그인 정보를 받지 못했습니다.\n다시 로그인해 주세요.',
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

      await _showErrorDialog(
        '회원가입 처리 중 오류가 발생했습니다.\n잠시 후 다시 시도해 주세요.',
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
              decoration: _inputDecoration(
                '질환명',
                Icons.medical_information_outlined,
                errorText: _otherDiseaseError,
              ),
            ),
          ),

        diseaseOption('NONE', '없음'),

        if (_diseaseError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              _diseaseError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),

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


  InputDecoration _inputDecoration(
      String hint,
      IconData icon, {
        String? errorText,
      }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: errorText != null
            ? Colors.red
            : const Color(0xFF9CA3AF),
        size: 22,
      ),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 12,
      ),

      // 오류 문구
      errorText: errorText,
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: errorText != null
            ? const BorderSide(color: Colors.red, width: 1.5)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _confirmPasswordError ==
              '비밀번호가 일치하지 않습니다.'
              ? Colors.red
              : const Color(0xFF377DCE),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
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
                        decoration: _inputDecoration(
                          '이름',
                          Icons.person_outline,
                          errorText: _nameError,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                        decoration: _inputDecoration(
                          '이메일',
                          Icons.mail_outline,
                          errorText: _emailError,
                        ),
                      ),
                      const SizedBox(height: 16),


                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        onChanged: _onPasswordChanged,
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                        decoration: _inputDecoration(
                          '비밀번호',
                          Icons.lock_outline,
                          errorText: _passwordError,
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: confirmPasswordController,
                        focusNode: confirmPasswordFocusNode,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onChanged: _onPasswordChanged,
                        onSubmitted: (_) {
                          confirmPasswordFocusNode.unfocus();
                        },
                        decoration: _inputDecoration(
                          '비밀번호 확인',
                          Icons.lock_outline,
                          errorText: _confirmPasswordError,
                        ),
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
