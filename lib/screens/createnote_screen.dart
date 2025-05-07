import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'note_screen.dart';

class CreateNoteScreen extends StatefulWidget {
  const CreateNoteScreen({super.key});

  @override
  CreateNoteScreenState createState() => CreateNoteScreenState();
}

class CreateNoteScreenState extends State<CreateNoteScreen> {
  final _titleController = TextEditingController();
  final _hostPasswordController = TextEditingController();
  final _guestPasswordController = TextEditingController();
  final _database = FirebaseDatabase.instance.ref();
  bool _isCreating = false; // 생성 중 상태 관리

  // 4자리 랜덤 숫자 생성 함수
  String _generateRandomPassword() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString(); // 1000-9999 사이의 숫자
  }

  // 노트 ID 중복 체크 함수 추가
  Future<bool> _isNoteIdAvailable(String noteId) async {
    try {
      final snapshot = await _database.child('notes/$noteId').get();
      if (!mounted) return false; // mounted 체크 추가
      return !snapshot.exists;
    } catch (e) {
      if (!mounted) return false; // mounted 체크 추가
      _showError('데이터베이스 접근 중 오류가 발생했습니다');
      return false;
    }
  }

  // 고유한 노트 ID 생성 함수 수정
  Future<String?> _generateUniqueNoteId() async {
    int attempts = 0;
    const maxAttempts = 5;

    while (attempts < maxAttempts) {
      final noteId = (100000 + Random().nextInt(900000)).toString();
      if (await _isNoteIdAvailable(noteId)) {
        return noteId;
      }
      attempts++;
    }

    if (!mounted) return null; // mounted 체크 추가
    _showError('노트 ID 생성에 실패했습니다. 잠시 후 다시 시도해주세요.');
    return null;
  }

  // 에러 표시 함수 개선
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '확인',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // 노트 생성 함수 수정
  Future<void> _createNote() async {
    if (_isCreating) return;

    final title = _titleController.text.trim();
    final currentContext = context; // BuildContext를 로컬 변수로 저장

    if (title.isEmpty) {
      _showError('노트 제목을 입력해주세요');
      return;
    }

    setState(() => _isCreating = true);

    try {
      // 고유한 노트 ID 생성
      final noteId = await _generateUniqueNoteId();
      if (noteId == null) {
        setState(() => _isCreating = false);
        return;
      }

      // 비밀번호 생성 또는 검증
      final hostPassword = _hostPasswordController.text.isEmpty
          ? _generateRandomPassword()
          : _hostPasswordController.text;
      final guestPassword = _guestPasswordController.text.isEmpty
          ? _generateRandomPassword()
          : _guestPasswordController.text;

      if (hostPassword == guestPassword) {
        _showError('호스트와 게스트 비밀번호는 서로 달라야 합니다');
        setState(() => _isCreating = false);
        return;
      }

      // 트랜잭션을 사용하여 안전하게 노트 생성
      final noteRef = _database.child('notes/$noteId');
      await noteRef.set({
        'title': title,
        'hostPassword': hostPassword,
        'guestPassword': guestPassword,
        'note': '',
        'createdAt': ServerValue.timestamp,
        'lastModified': ServerValue.timestamp,
      }).then((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          currentContext, // 저장된 context 사용
          MaterialPageRoute(
            builder: (context) => NoteScreen(
              noteId: noteId,
              password: hostPassword,
              isHost: true,
              username: '호스트',
              noteTitle: title,
            ),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      _showError('노트 생성 중 오류가 발생했습니다: ${e.toString()}');
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 1200
                    ? ((MediaQuery.of(context).size.width - 1200) / 2)
                        .clamp(16.0, 200.0)
                    : 16.0,
                vertical: 16.0,
              ),
              child: Card(
                elevation: 2,
                color: Colors.grey[850],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '새 노트',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 24),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: '노트 제목',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      TextField(
                        controller: _hostPasswordController,
                        decoration: InputDecoration(
                          labelText: '호스트 비밀번호 (4자리 숫자)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.refresh),
                            onPressed: () {
                              setState(() {
                                _hostPasswordController.text =
                                    _generateRandomPassword();
                              });
                            },
                            tooltip: '랜덤 생성',
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: false, // 비밀번호 표시
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _guestPasswordController,
                        decoration: InputDecoration(
                          labelText: '게스트 비밀번호 (4자리 숫자)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.refresh),
                            onPressed: () {
                              setState(() {
                                _guestPasswordController.text =
                                    _generateRandomPassword();
                              });
                            },
                            tooltip: '랜덤 생성',
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: false, // 비밀번호 표시
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                        ),
                        onPressed: _isCreating ? null : _createNote,
                        child: _isCreating
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                '노트 생성',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
