import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isSaving = false;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  final confirmPasswordFocusNode = FocusNode();


  @override
  void initState() {
    super.initState();

    confirmPasswordFocusNode.addListener(() {
      if (!confirmPasswordFocusNode.hasFocus && mounted) {
        _validatePasswordMatch();
      }
    });
  }

  void _validatePasswordMatch() {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (confirmPassword.isEmpty) return;

    setState(() {
      _confirmPasswordError =
      newPassword != confirmPassword
          ? '비밀번호가 일치하지 않습니다.'
          : null;
    });
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'current':
          _currentPasswordError = null;
          break;
        case 'new':
          _newPasswordError = null;
          _confirmPasswordError = null;
          break;
        case 'confirm':
          _confirmPasswordError = null;
          break;
      }
    });
  }


  InputDecoration _passwordDecoration(
      String hint,
      String? error,
      ) {
    OutlineInputBorder border(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      errorText: error,
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
      border: border(Colors.transparent, 0),
      enabledBorder: border(
        error == null ? Colors.transparent : Colors.red,
        error == null ? 0 : 1.5,
      ),
      focusedBorder: border(const Color(0xFF377DCE), 1.5),
      errorBorder: border(Colors.red, 1.5),
      focusedErrorBorder: border(Colors.red, 1.5),
    );
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
                  : Icons.error_outline_rounded,
              color: success
                  ? const Color(0xFF377DCE)
                  : Colors.red,
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


  Future<void> _changePassword() async {
    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;


    String? currentError;
    String? newError;
    String? confirmError;

    if (currentPassword.isEmpty) {
      currentError = '현재 비밀번호를 입력해 주세요.';
    }

    if (newPassword.isEmpty) {
      newError = '새 비밀번호를 입력해 주세요.';
    } else if (newPassword.length < 4) {
      newError = '새 비밀번호는 4자 이상이어야 합니다.';
    }

    if (confirmPassword.isEmpty) {
      confirmError = '새 비밀번호를 다시 입력해 주세요.';
    } else if (newPassword.isNotEmpty &&
        newPassword != confirmPassword) {
      confirmError = '비밀번호가 일치하지 않습니다.';
    }

    if (currentPassword.isNotEmpty &&
        newPassword.isNotEmpty &&
        currentPassword == newPassword) {
      newError = '기존 비밀번호와 다르게 설정해 주세요.';
    }

    setState(() {
      _currentPasswordError = currentError;
      _newPasswordError = newError;
      _confirmPasswordError = confirmError;
    });

    if (currentError != null ||
        newError != null ||
        confirmError != null) {
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

      // 3. 비밀번호 변경 API 호출
      final response = await http.put(
        Uri.parse('http://localhost:8080/api/users/me/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await _showResultDialog(
          '변경 완료',
          '비밀번호가 변경되었습니다.',
          success: true,
        );

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        String errorMessage = '비밀번호 변경에 실패했습니다.';

        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));

          if (data is Map && data['message'] is String) {
            errorMessage = data['message'];
          }
        } catch (e) {
          debugPrint('오류 응답 파싱 실패: $e');
        }

        if (!mounted) return;

        if (errorMessage.contains('현재 비밀번호')) {
          setState(() {
            _currentPasswordError = errorMessage;
          });
        } else {
          await _showResultDialog(
            '변경 실패',
            errorMessage,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('비밀번호 변경 요청 오류: $e');

      await _showResultDialog(
        '오류 발생',
        '비밀번호 변경 중 오류가 발생했습니다.\n잠시 후 다시 시도해 주세요.',
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
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 변경'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '현재 비밀번호',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              onChanged: (_) => _clearError('current'),
              decoration: _passwordDecoration(
                '현재 비밀번호를 입력하세요',
                _currentPasswordError,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '새 비밀번호',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              onChanged: (_) => _clearError('new'),
              decoration: _passwordDecoration(
                '8자 이상 입력하세요',
                _newPasswordError,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPasswordController,
              focusNode: confirmPasswordFocusNode,
              obscureText: true,
              onChanged: (_) => _clearError('confirm'),
              decoration: _passwordDecoration(
                '새 비밀번호를 다시 입력하세요',
                _confirmPasswordError,
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _changePassword,
                child: Text(
                  isSaving ? '변경 중...' : '비밀번호 변경',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}