// FlutterFire CLI로 자동 생성된 파일
// Firebase 프로젝트 설정 정보를 포함
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase 앱 설정을 위한 기본 옵션 클래스
///
/// 사용 예시:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  // 현재 플랫폼에 맞는 Firebase 설정을 반환
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // 웹 플랫폼용 Firebase 설정
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDypJKkYoeF9G3iKCWikgHSitnVYokuPdw',
    appId: '1:281684919727:web:bbea05391e135cc2af5b5a',
    messagingSenderId: '281684919727',
    projectId: 'livenote-caf0d',
    authDomain: 'livenote-caf0d.firebaseapp.com',
    databaseURL:
        'https://livenote-caf0d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'livenote-caf0d.appspot.com',
    measurementId: 'G-BP6RM50F3V',
  );

  // Android 플랫폼용 Firebase 설정
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDX0JzlxMCMJLyjD03hjxGX1gIBxVc33OM',
    appId: '1:281684919727:android:ad21eb84b09e4206af5b5a',
    messagingSenderId: '281684919727',
    projectId: 'livenote-caf0d',
    storageBucket: 'livenote-caf0d.firebasestorage.app',
  );

  // iOS 플랫폼용 Firebase 설정
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCYumHLqfU9dJcJckHXcxBKfnf2Khhx9DI',
    appId: '1:281684919727:ios:5156810c2bf45c33af5b5a',
    messagingSenderId: '281684919727',
    projectId: 'livenote-caf0d',
    storageBucket: 'livenote-caf0d.firebasestorage.app',
    iosBundleId: 'com.example.liveNote',
  );

  // macOS 플랫폼용 Firebase 설정
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCYumHLqfU9dJcJckHXcxBKfnf2Khhx9DI',
    appId: '1:281684919727:ios:5156810c2bf45c33af5b5a',
    messagingSenderId: '281684919727',
    projectId: 'livenote-caf0d',
    storageBucket: 'livenote-caf0d.firebasestorage.app',
    iosBundleId: 'com.example.liveNote',
  );

  // Windows 플랫폼용 Firebase 설정
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDypJKkYoeF9G3iKCWikgHSitnVYokuPdw',
    appId: '1:281684919727:web:1f08a57dd9517f6faf5b5a',
    messagingSenderId: '281684919727',
    projectId: 'livenote-caf0d',
    authDomain: 'livenote-caf0d.firebaseapp.com',
    storageBucket: 'livenote-caf0d.firebasestorage.app',
    measurementId: 'G-N1XZZJPYRC',
  );
}
