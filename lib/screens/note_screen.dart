import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class NoteScreen extends StatefulWidget {
  final String noteId;
  final String password;
  final bool isHost;
  final String username;
  final String noteTitle;

  NoteScreen({
    required this.noteId,
    required this.password,
    required this.isHost,
    required this.username,
    required this.noteTitle,
  });

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _noteController = TextEditingController();
  bool _canEdit = false;
  final List<String> _editRequests = [];
  OverlayEntry? _requestOverlay;

  final List<String> _editingUsers = [];
  OverlayEntry? _editingOverlay;

  // Map to track timers for each edit request
  final Map<String, Timer> _editRequestTimers = {};

  bool _isGuestListOpen = false; // 게스트 목록 표시 여부
  List<String> _connectedGuests = []; // 접속 중인 게스트 목록

  @override
  void initState() {
    super.initState();
    _addConnectedUser();
    if (widget.isHost) {
      _resetAllPermissions(); // 호스트 접속 시 모든 권한 초기화
    }
    _listenForNoteChanges();
    _checkEditPermission();
    if (widget.isHost) {
      _listenForEditRequests();
      _listenForEditingUsers();
      _listenForConnectedGuests();
    }
  }

  @override
  void dispose() {
    _removeConnectedUser();
    _noteController.dispose();
    _requestOverlay?.remove();
    _editingOverlay?.remove();
    _editRequestTimers.values.forEach((timer) => timer.cancel());
    super.dispose();
  }

  void _listenForNoteChanges() {
    final noteRef = _database.child('notes/${widget.noteId}');

    // 노트 내용 변경 감지
    noteRef.child('note').onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value != null) {
        setState(() {
          _noteController.text = event.snapshot.value.toString();
        });
      }
    });

    // 편집 중인 사용자 목록 감지
    noteRef.child('editing').onValue.listen((event) {
      if (!mounted) return;
      setState(() {
        _editingUsers.clear();
        if (event.snapshot.value != null) {
          final editing =
              Map<String, dynamic>.from(event.snapshot.value as Map);
          _editingUsers.addAll(editing.keys);

          // 누군가 편집 중일 때는 다른 사용자의 편집 기능 비활성화
          if (_editingUsers.isNotEmpty &&
              !_editingUsers.contains(widget.username)) {
            _canEdit = false;
          }
        }
        _updateEditingOverlay();
      });
    });
  }

  void _checkEditPermission() {
    if (widget.isHost) {
      _database.child('notes/${widget.noteId}/editing').onValue.listen((event) {
        setState(() {
          if (event.snapshot.value == null) {
            _canEdit = true;
          } else {
            final editing =
                Map<String, dynamic>.from(event.snapshot.value as Map);
            _canEdit = editing.isEmpty;
          }
        });
      });
    } else {
      _database
          .child('notes/${widget.noteId}/editPermission/${widget.username}')
          .onValue
          .listen((event) {
        setState(() {
          _canEdit = event.snapshot.value == true;
          if (_canEdit) {
            // 편집 권한을 받으면 editing 상태 업데이트
            _database
                .child('notes/${widget.noteId}/editing/${widget.username}')
                .set(true);
          }
        });
      });
    }
  }

  void _updateNote() {
    if (_canEdit) {
      _database.child('notes/${widget.noteId}').update({
        'note': _noteController.text,
        'lastModified': ServerValue.timestamp,
      });
    }
  }

  void _requestEditPermission() {
    _database
        .child('notes/${widget.noteId}/editRequests/${widget.username}')
        .set(true)
        .catchError((error) {
      print('Error requesting edit permission: $error');
    });
  }

  void _listenForEditRequests() {
    _database
        .child('notes/${widget.noteId}/editRequests')
        .onValue
        .listen((event) {
      if (!mounted || !widget.isHost) return;

      final prevRequests = Set<String>.from(_editRequests);

      if (event.snapshot.value != null) {
        final requests = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _editRequests.clear();
          _editRequests.addAll(requests.keys);
        });

        print('수정 요청 감지: $_editRequests'); // 디버깅용 로그
      } else {
        setState(() {
          _editRequests.clear();
        });
      }

      for (var guest in _editRequests) {
        if (!_editRequestTimers.containsKey(guest)) {
          _startRequestTimer(guest);
        }
      }

      for (var oldGuest in prevRequests.difference(_editRequests.toSet())) {
        _cancelAndRemoveTimerForGuest(oldGuest);
      }

      // 요청이 변경될 때마다 오버레이 업데이트
      _refreshRequestOverlay();
    });
  }

  void _listenForEditingUsers() {
    _database
        .child('notes/${widget.noteId}/editPermission')
        .onValue
        .listen((event) {
      if (!widget.isHost) return;

      if (event.snapshot.value != null) {
        final permissions =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _editingUsers.clear();
          _editingUsers.addAll(permissions.keys);
        });
      } else {
        setState(() {
          _editingUsers.clear();
        });
      }

      _refreshEditingOverlay();
    });
  }

  void _startRequestTimer(String guestName) {
    _editRequestTimers[guestName]?.cancel();
    _editRequestTimers[guestName] = Timer(Duration(seconds: 20), () {
      _clearSingleRequestFromDB(guestName);
    });
  }

  void _clearSingleRequestFromDB(String guestName) {
    _database.child('notes/${widget.noteId}/editRequests/$guestName').remove();
    setState(() {
      _editRequests.remove(guestName);
      _cancelAndRemoveTimerForGuest(guestName);
      _refreshRequestOverlay();
    });
  }

  void _cancelAndRemoveTimerForGuest(String guestName) {
    _editRequestTimers[guestName]?.cancel();
    _editRequestTimers.remove(guestName);
  }

  void _grantEditPermission(String guestName) {
    // 다른 사용자가 편집 중이면 권한 부여하지 않음
    if (_editingUsers.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('다른 사용자가 이미 편집 중입니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _database.child('notes/${widget.noteId}/editRequests/$guestName').remove();
    _database
        .child('notes/${widget.noteId}/editPermission/$guestName')
        .set(true);

    setState(() {
      _editRequests.remove(guestName);
      _cancelAndRemoveTimerForGuest(guestName);
      _refreshRequestOverlay();
    });
  }

  void _refreshRequestOverlay() {
    _requestOverlay?.remove();
    _requestOverlay = null;

    if (_editRequests.isNotEmpty && widget.isHost && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showEditRequestOverlay();
        }
      });
    }
  }

  void _refreshEditingOverlay() {
    _editingOverlay?.remove();
    _editingOverlay = null;
    if (_editingUsers.isNotEmpty && widget.isHost) {
      _showEditingUsersOverlay();
    }
  }

  void _showEditRequestOverlay() {
    if (!mounted) return;

    _requestOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0,
        right: 10.0,
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _editRequests.map((guestName) {
              return Container(
                margin: EdgeInsets.only(bottom: 8.0),
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$guestName 님이 수정 권한을 요청했습니다.',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _grantEditPermission(guestName),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (mounted) {
      Overlay.of(context).insert(_requestOverlay!);
    }
  }

  void _showEditingUsersOverlay() {
    _editingOverlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50.0,
        right: 10.0,
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _editingUsers.map((guestName) {
              return Container(
                margin: EdgeInsets.only(bottom: 8.0),
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '$guestName 님이 수정 중입니다.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_editingOverlay!);
  }

  // 접속 중인 게스트 목록 감지
  void _listenForConnectedGuests() {
    _database
        .child('notes/${widget.noteId}/connectedUsers')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final users = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _connectedGuests =
              users.keys.where((user) => user != widget.username).toList();
        });
      } else {
        setState(() {
          _connectedGuests = [];
        });
      }
    });
  }

  // 접속 사용자 추가
  void _addConnectedUser() {
    _database
        .child('notes/${widget.noteId}/connectedUsers/${widget.username}')
        .set(true)
        .catchError((error) {
      print('Error adding connected user: $error');
    });
  }

  // 접속 사용자 제거
  void _removeConnectedUser() {
    _database
        .child('notes/${widget.noteId}/connectedUsers/${widget.username}')
        .remove()
        .catchError((error) {
      print('Error removing connected user: $error');
    });
  }

  // 상단 사용자 정보 위젯
  Widget _buildUserInfoBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: widget.isHost
              ? () {
                  setState(() {
                    _isGuestListOpen = !_isGuestListOpen;
                  });
                }
              : null,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(8),
            color: Colors.grey[850],
            child: Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).iconTheme.color),
                SizedBox(width: 8),
                Text(
                  widget.username,
                  style: TextStyle(color: Colors.grey[400]),
                ),
                if (widget.isHost) ...[
                  SizedBox(width: 4),
                  Icon(
                    _isGuestListOpen
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: Colors.grey[400],
                  ),
                ],
                Spacer(),
                Text(
                  widget.isHost ? '호스트' : '게스트',
                  style: TextStyle(
                    color: widget.isHost ? Colors.blue : Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isGuestListOpen && widget.isHost)
          Container(
            color: Colors.grey[900],
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '접속 중인 게스트',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                if (_connectedGuests.isEmpty)
                  Text(
                    '접속 중인 게스트가 없습니다',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  )
                else
                  ..._connectedGuests
                      .map((guest) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  guest,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
              ],
            ),
          ),
      ],
    );
  }

  // 편집 중인 게스트 목록을 표시하는 오버레이 업데이트
  void _updateEditingOverlay() {
    _editingOverlay?.remove();
    if (_editingUsers.isEmpty || !widget.isHost) {
      _editingOverlay = null;
      return;
    }

    _editingOverlay = OverlayEntry(
      builder: (context) => Positioned(
        right: 16,
        bottom: 16,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _cancelAllEditPermissions();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '${_editingUsers.join(", ")} 수정 중...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (mounted) {
      Overlay.of(context).insert(_editingOverlay!);
    }
  }

  // 모든 게스트의 편집 권한 취소 함수 수정
  void _cancelAllEditPermissions() {
    final noteRef = _database.child('notes/${widget.noteId}');

    // 편집 중 상태 제거
    noteRef.child('editing').remove();

    // 편집 권한 제거
    noteRef.child('editPermission').remove();

    // 편집 요청 제거
    noteRef.child('editRequests').remove();

    // 상태 업데이트
    setState(() {
      _editingUsers.clear();
      _editingOverlay?.remove();
      _editingOverlay = null;
    });
  }

  // 모든 편집 권한과 요청을 초기화하는 메서드
  void _resetAllPermissions() {
    final noteRef = _database.child('notes/${widget.noteId}');

    // 편집 권한, 편집 중 상태, 편집 요청을 한 번에 초기화
    Map<String, dynamic> updates = {
      'editPermission': null, // null로 설정하여 노드 삭제
      'editing': null,
      'editRequests': null,
    };

    noteRef.update(updates).then((_) {
      setState(() {
        _editingUsers.clear();
        _editRequests.clear();
        _canEdit = widget.isHost; // 호스트만 편집 가능하도록 설정
      });
    }).catchError((error) {
      print('Error resetting permissions: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1200),
            child: Row(
              children: [
                Spacer(),
                if (widget.isHost)
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: _confirmDeleteNote,
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _canEdit
                            ? Colors.green.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _canEdit ? '수정 가능' : '읽기 전용',
                        style: TextStyle(
                          color: _canEdit ? Colors.green : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
              child: Column(
                children: [
                  _buildUserInfoBar(),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Text(
                          '■ ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.noteTitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '(ID: ${widget.noteId})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.share, size: 20, color: Colors.blue),
                          tooltip: '공유 링크 복사',
                          onPressed: () {
                            final shareUrl =
                                'https://livenote-caf0d.firebaseapp.com/?noteId=${widget.noteId}';
                            Clipboard.setData(ClipboardData(text: shareUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('노트 링크가 클립보드에 복사되었습니다.'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          TextField(
                            controller: _noteController,
                            maxLines: null,
                            expands: true,
                            enabled: _canEdit,
                            style: TextStyle(
                              color: _canEdit ? Colors.white : Colors.grey[400],
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[850],
                              alignLabelWithHint: false,
                              hintText:
                                  _canEdit ? '여기에 내용을 입력하세요...' : '수정 권한이 없습니다',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.all(16),
                            ),
                            textAlignVertical: TextAlignVertical.top,
                            onChanged: (value) {
                              _updateNote();
                            },
                          ),
                          if (!_canEdit)
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () {}, // 터치 이벤트 차단
                                child: Container(
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: widget.isHost
          ? null
          : FloatingActionButton.extended(
              onPressed:
                  _canEdit ? _removeEditPermission : _requestEditPermission,
              icon: Icon(_canEdit ? Icons.close : Icons.edit),
              label: Text(_canEdit ? '수정 중지' : '수정 요청'),
              backgroundColor: _canEdit ? Colors.red : Colors.blue,
            ),
    );
  }

  void _removeEditPermission() {
    _database
        .child('notes/${widget.noteId}/editPermission/${widget.username}')
        .remove();
    _database
        .child('notes/${widget.noteId}/editing/${widget.username}')
        .remove();
    setState(() {
      _canEdit = false;
    });
  }

  void _confirmDeleteNote() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            '노트 삭제',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '정말로 이 노트를 삭제하시겠습니까?',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                '삭제',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                _deleteNote();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteNote() {
    _database.child('notes/${widget.noteId}').remove().then((_) {
      Navigator.of(context).pop(); // 노트 삭제 후 이전 화면으로 돌아가기
    }).catchError((error) {
      print('Error deleting note: $error');
    });
  }
}
