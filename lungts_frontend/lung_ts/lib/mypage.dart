import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'signin.dart';
import 'edit_profile.dart';

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
            : '기타 ($otherDiseaseName)',
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (!mounted) return;

        setState(() {
          userName = data['name'] ?? '사용자';
          userEmail = data['email'] ?? '';

          userDiseases = Set<String>.from(data['diseases'] ?? []);
          otherDiseaseName = data['otherDiseaseName'] ?? '';
        });
      } else {
        debugPrint('사용자 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('사용자 조회 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userName님의 마이페이지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();

              // Spring Boot 로그인 JWT 삭제
              await prefs.remove('jwt_token');

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignInScreen(),
                ),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 사용자 정보
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(
              '$userName님',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(userEmail),
                const SizedBox(height: 6),
                Text(
                  '질환: $diseaseText',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // 회원 정보 수정
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('회원 정보 수정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );

              if (updated == true && mounted) {
                _loadUserInfo();
              }
            },
          ),

          const Divider(),

          // 약 정보 수정
          ListTile(
            leading: const Icon(Icons.medication_outlined),
            title: const Text('약 정보 수정'),
            subtitle: const Text('등록한 약 조회, 추가, 삭제'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 추후 약 정보 수정 화면 연결
            },
          ),

          const Divider(),

          // 회원 탈퇴
          ListTile(
            leading: const Icon(
              Icons.person_remove_outlined,
              color: Colors.red,
            ),
            title: const Text(
              '회원 탈퇴',
              style: TextStyle(color: Colors.red),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 추후 회원 탈퇴 API 연결
            },
          ),
        ],
      ),

    );
  }
}
