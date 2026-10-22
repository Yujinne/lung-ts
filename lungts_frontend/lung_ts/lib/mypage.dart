import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'medicine_edit.dart';
import 'signin.dart';
import 'edit_profile.dart';
import 'transition_helper.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String userName = '사용자';
  String userEmail = '';
  Set<String> userDiseases = {};
  String otherDiseaseName = '';

  static const Color primaryBlue = Color(0xFF377DCE);
  static const Color pageBackground = Color(0xFFF9FAFB);

  String get diseaseText {
    if (userDiseases.isEmpty) return '미등록';

    final labels = <String>[];

    if (userDiseases.contains('ASTHMA')) {
      labels.add('천식');
    }

    if (userDiseases.contains('COPD')) {
      labels.add('COPD');
    }

    if (userDiseases.contains('OTHER')) {
      labels.add(
        otherDiseaseName.isEmpty
            ? '기타'
            : '$otherDiseaseName',
      );
    }

    if (userDiseases.contains('NONE')) {
      labels.add('없음');
    }

    return labels.join(', ');
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (!mounted) return;

        setState(() {
          userName = data['name'] ?? '사용자';
          userEmail = data['email'] ?? '';
          userDiseases = Set<String>.from(
            data['diseases'] ?? [],
          );
          otherDiseaseName = data['otherDiseaseName'] ?? '';
        });
      } else {
        debugPrint('사용자 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('사용자 조회 오류: $e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const SignInScreen(),
      ),
          (route) => false,
    );
  }


  Future<void> _confirmLogout() async {
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
                Icons.logout,
                color: Color(0xFF377DCE),
              ),
              SizedBox(width: 10),
              Text('로그아웃'),
            ],
          ),
          content: const Text(
            '로그아웃하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text(
                '취소',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text(
                '로그아웃',
                style: TextStyle(
                  color: Color(0xFF377DCE),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _logout();
  }



  Future<void> _withdraw() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final response = await http.delete(
        Uri.parse('http://localhost:8080/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        // 탈퇴 성공 시 JWT 삭제
        await prefs.remove('jwt_token');

        if (!mounted) return;

        // 로그인 화면으로 이동
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const SignInScreen(),
          ),
              (route) => false,
        );
      } else {
        throw Exception('회원 탈퇴 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원 탈퇴 중 오류가 발생했습니다: $e'),
        ),
      );
    }
  }



  Future<void> _confirmWithdrawal() async {
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
                Icons.person_remove_outlined,
                color: Color(0xFFE45252),
              ),
              SizedBox(width: 10),
              Text('회원 탈퇴'),
            ],
          ),
          content: const Text(
            '정말 탈퇴하시겠습니까?\n\n'
                '탈퇴하면 계정에 접근할 수 없으며,\n'
                '관련 정보가 삭제될 수 있습니다.',
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
                '탈퇴하기',
                style: TextStyle(
                  color: Color(0xFFE45252),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _withdraw();
  }


  // 공통 카드 디자인
  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: child,
    );
  }

  // 메뉴 카드
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final iconColor = isDanger
        ? const Color(0xFFE45252)
        : primaryBlue;

    final iconBackground = isDanger
        ? const Color(0xFFFFF0F0)
        : const Color(0xFFE8F1FF);

    return _buildCard(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 20,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDanger
                              ? iconColor
                              : const Color(0xFF202936),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B929D),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 내 정보 카드
  Widget _buildProfileCard() {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F1FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: primaryBlue,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$userName님',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202936),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7A8492),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Divider(
              color: Color(0xFFEEF0F4),
              height: 1,
            ),

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '등록 질환',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7A8492),
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Text(
                    diseaseText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF202936),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,

      appBar: AppBar(
        backgroundColor: pageBackground,
        elevation: 0,
        title: const Text(
          '마이페이지',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF202936),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: IconButton(
              icon: const Icon(
                Icons.logout,
                color: Color(0xFF6B7280),
              ),
              tooltip: '로그아웃',
              onPressed: _confirmLogout,
            ),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20, 20, 20, 30,
        ),
        children: [
          // 1. 내 정보 카드
          _buildProfileCard(),

          const SizedBox(height: 6),

          // 2. 회원 정보 수정 카드
          _buildMenuCard(
            icon: Icons.edit_outlined,
            title: '회원 정보 수정',
            subtitle: '이름, 비밀번호 및 질환 정보 관리',
            onTap: () async {
              final updated = await Navigator.push<bool>(
                context,
                slideFromRight(const EditProfileScreen()),
              );

              if (updated == true && mounted) {
                _loadUserInfo();
              }
            },
          ),

          // 3. 약 정보 수정 카드
          _buildMenuCard(
            icon: Icons.medication_outlined,
            title: '약 정보 수정',
            subtitle: '등록한 약 조회, 추가, 삭제',
            onTap: () {
              Navigator.push(
                context,
                slideFromRight(const MedicineEditScreen()),
              );
            },
          ),

          // 4. 회원 탈퇴 카드
          _buildMenuCard(
            icon: Icons.person_remove_outlined,
            title: '회원 탈퇴',
            subtitle: '계정 및 회원 정보 삭제',
            isDanger: true,
            onTap: _confirmWithdrawal,
          ),
        ],
      ),
    );
  }
}
