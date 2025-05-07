# Live Note - 실시간 공유 노트 애플리케이션

Live Note는 Flutter로 개발된 실시간 노트 공유 애플리케이션입니다. 사용자가 노트를 생성하고 다른 사용자와 실시간으로 공유할 수 있는 플랫폼을 제공합니다.

## 주요 기능

- **실시간 노트 공유**: 호스트가 생성한 노트를 다수의 게스트와 공유 가능
- **실시간 동기화**: Firebase Realtime Database를 활용한 실시간 콘텐츠 동기화
- **편집 권한 관리**: 호스트가 게스트의 편집 요청을 관리하고, 동시 편집 충돌 방지
- **접속자 현황 보기**: 현재 접속 중인 사용자 확인 가능
- **비밀번호 보호**: 호스트와 게스트별 독립적인 비밀번호로 노트 보호
- **반응형 디자인**: 모바일부터 데스크톱까지 다양한 화면 크기 지원

## 기술 스택

- **프론트엔드**: Flutter
- **백엔드**: Firebase Realtime Database
- **인증**: Firebase Authentication (익명 인증)
- **호스팅**: Firebase Hosting
- **상태 관리**: Flutter의 StatefulWidget 활용

## 프로젝트 구조

```
lib/
├── main.dart              # 앱 진입점
├── screens/
│   ├── home_screen.dart      # 홈 화면 (노트 목록, 노트 참여)
│   ├── createnote_screen.dart # 노트 생성 화면
│   └── note_screen.dart      # 노트 편집 화면
└── widgets/
    └── folded_card.dart      # 커스텀 카드 위젯
```

## 핵심 컴포넌트

### HomeScreen
- 노트 목록 표시
- 노트 ID, 비밀번호로 참여하기
- 노트 검색 기능
- 새 노트 생성 기능

### CreateNoteScreen
- 노트 제목 설정
- 호스트/게스트 비밀번호 설정
- 고유한 노트 ID 자동 생성

### NoteScreen
- 실시간 노트 내용 표시 및 편집
- 호스트의 편집 권한 관리
- 게스트의 편집 요청 기능
- 현재 접속자 목록 표시
- 노트 삭제 기능 (호스트 전용)

## 데이터 모델

Firebase Realtime Database의 데이터 구조:

```
notes/
├── {noteId}/
│   ├── title: String
│   ├── note: String
│   ├── hostPassword: String
│   ├── guestPassword: String
│   ├── createdAt: Timestamp
│   ├── lastModified: Timestamp
│   ├── connectedUsers/
│   │   └── {username}: Boolean
│   ├── editPermission/
│   │   └── {username}: Boolean
│   ├── editing/
│   │   └── {username}: Boolean
│   └── editRequests/
│       └── {username}: Boolean
```

## 기능 흐름

1. **노트 생성**:
   - 사용자가 제목과 비밀번호 설정
   - 고유한 노트 ID 생성
   - Firebase에 노트 데이터 저장

2. **노트 참여**:
   - 사용자가 노트 ID, 사용자 이름, 비밀번호 입력
   - 호스트 또는 게스트로 인증
   - 해당 노트 화면으로 이동

3. **편집 요청 및 권한 관리**:
   - 게스트가 편집 요청 전송
   - 호스트가 요청 수락/거부
   - 호스트는 언제든지 편집 권한 취소 가능

4. **실시간 동기화**:
   - 노트 내용 변경 시 모든 접속자에게 실시간 반영
   - 편집 중인 사용자 상태 표시
   - 접속자 목록 실시간 업데이트

## 빌드 및 실행 방법

### 사전 준비

1. Flutter SDK 설치
   ```bash
   # Flutter SDK 다운로드 및 설치: https://flutter.dev/docs/get-started/install
   ```

2. Firebase 프로젝트 설정
   ```bash
   # Firebase CLI 설치
   npm install -g firebase-tools
   
   # Firebase에 로그인
   firebase login
   ```

3. 필요한 종속성 설치
   ```bash
   flutter pub get
   ```

### 로컬 개발 환경 실행

1. Firebase 프로젝트 연결
   ```bash
   # 앱과 Firebase 프로젝트 연결
   flutterfire configure --project=your-firebase-project-id
   ```

2. 개발 서버 실행
   ```bash
   # 디버그 모드로 실행
   flutter run
   
   # 웹 실행
   flutter run -d chrome
   ```

### 프로덕션 빌드

1. 웹 빌드
   ```bash
   flutter build web
   ```

2. Firebase 호스팅에 배포
   ```bash
   firebase deploy --only hosting
   ```

3. 모바일 앱 빌드
   ```bash
   # Android APK 빌드
   flutter build apk --release
   
   # iOS 빌드
   flutter build ios --release
   ```

## 개선 사항 및 향후 계획

- 노트 공유 URL 기능: 웹 URL을 통한 손쉬운 노트 접근
- 푸시 알림: 편집 요청 및 변경 사항에 대한 알림
- 다국어 지원: 한국어 이외의 언어 지원
- 리치 텍스트 편집기: 서식 있는 텍스트 지원
- 오프라인 지원: 오프라인 상태에서도 노트 작성 가능
- 사용자 계정: 구글, 이메일 등을 통한 사용자 인증
- 노트 템플릿: 자주 사용하는 형식의 노트 템플릿 제공

## 업데이트 기록

### v1.0.2 (현재)
- **호스트 접속 상태 실시간 감지**: 게스트가 호스트 접속 상태를 실시간으로 확인 가능
- **수정 요청 버튼 개선**: 호스트 접속 여부에 따라 버튼 상태 자동 변경
- **타입 오류 수정**: Firebase 데이터 처리 시 타입 안전성 개선
- **UX 개선**: 호스트가 접속 중일 때만 수정 요청 가능하도록 변경

### v1.0.1
- **브라우저 종료 시 자동 연결 해제**: onDisconnect 메서드를 활용한 사용자 상태 관리 강화
- **동일 사용자 이름 중복 접속 방지**: 같은 이름으로 접속 시도 시 오류 메시지 표시
- **오류 메시지 개선**: "못된 비밀번호입니다" → "잘못된 비밀번호입니다" 등 사용자 친화적인 메시지로 수정
- **노트 공유 기능 추가**: URL 파라미터를 통한 노트 ID 자동 입력 지원

### v1.0.0
- **최초 릴리스**: 기본 실시간 노트 공유 기능 구현
- **Firebase 웹 호스팅 배포**: https://livenote-caf0d.web.app
- **GitHub 저장소 연결**: 버전 관리 설정 (main, release/v1.0 브랜치)
- **편집 권한 관리 시스템**: 호스트가 게스트의 수정 요청을 관리하는 기능 구현

## 라이선스

Copyright © 2023 LiveNote. All rights reserved.

