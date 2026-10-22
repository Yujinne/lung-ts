import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'signin.dart'; // SignIn 화면 import
import 'home.dart'; // Home 화면 import
import 'category_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/gestures.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  debugPrint('JWT 저장 여부: ${token != null && token.isNotEmpty}');

  bool isLoggedIn = false;

  if (token != null && token.isNotEmpty) {
    try {
      final parts = token.split('.');

      if (parts.length == 3) {
        final payload = jsonDecode(
          utf8.decode(
            base64Url.decode(base64Url.normalize(parts[1])),
          ),
        );

        final exp = payload['exp'];

        if (exp is num) {
          final expirationDate =
          DateTime.fromMillisecondsSinceEpoch(
            exp.toInt() * 1000,
          );

          isLoggedIn = expirationDate.isAfter(DateTime.now());

          debugPrint('JWT 만료 시간: $expirationDate');
          debugPrint('현재 시간: ${DateTime.now()}');
          debugPrint('로그인 상태: $isLoggedIn');
        }
      }
    } catch (e) {
      debugPrint('JWT 확인 오류: $e');
      isLoggedIn = false;
    }

    if (!isLoggedIn) {
      await prefs.remove('jwt_token');
    }
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auth',
      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3678C8),
          primary: const Color(0xFF3678C8),
          surface: Colors.white,
        ),

        scaffoldBackgroundColor: const Color(0xFFF9FAFB),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF9FAFB),
          foregroundColor: Colors.black,
          elevation: 0,
        ),

        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
        ),
      ),
      home: isLoggedIn
          ? const HomeScreen()
          : const SignInScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],

      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
    );
  }
}
