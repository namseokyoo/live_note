// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

// 앱의 메인 진입점 및 전역 설정을 담당하는 파일

class AuthService {
  // Firebase 익명 인증 및 노트 접근 권한을 관리하는 서비스 클래스
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<UserCredential> signInAnonymously() async {
    // 익명 사용자로 Firebase에 로그인
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print("익명 로그인 실패: $e");
      rethrow;
    }
  }

  Future<bool> verifyNoteAccess(String noteId, String password) async {
    // 노트 접근 권한 확인 (호스트 비밀번호 검증)
    try {
      if (_auth.currentUser == null) {
        await signInAnonymously();
      }

      final snapshot = await _database.child('notes/$noteId').get();
      if (!snapshot.exists) {
        return false;
      }

      final noteData = snapshot.value as Map<dynamic, dynamic>;
      return noteData['hostPassword'] == password;
    } catch (e) {
      print("노트 접근 확인 실패: $e");
      return false;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 앱의 전역 테마 및 라우팅 설정
  // - 다크 테마 기본 적용
  // - 커스텀 폰트 설정 (NotoSansKR, Pacifico)
  // - 버튼, 다이얼로그 등의 UI 컴포넌트 스타일 정의
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Note',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Pacifico',
            fontSize: 28,
            color: Colors.blue,
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.grey[850],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          labelStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          prefixIconColor: Colors.grey[400],
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'Pacifico',
            fontSize: 28,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(
          color: Colors.grey[400],
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            minimumSize: Size(100, 40),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            minimumSize: Size(100, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          extendedPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: TextStyle(
            color: Colors.grey[300],
            fontSize: 16,
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.grey[850],
          textStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: HomeScreen(),
    );
  }
}
