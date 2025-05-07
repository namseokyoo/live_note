// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'note_screen.dart';
import 'createnote_screen.dart';
import '../widgets/folded_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();
  final _noteIdController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      _fetchNotes();
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  Future<void> _fetchNotes() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await _database.child('notes').orderByChild('createdAt').get();

      if (!snapshot.exists || snapshot.value == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final notes = data.entries.map((e) {
        final noteData = Map<String, dynamic>.from(e.value);
        noteData['id'] = e.key;
        return noteData;
      }).toList();

      notes
          .sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));

      setState(() {
        _notes = notes;
        _filteredNotes = notes;
        _isLoading = false;
      });

      print('Fetched ${notes.length} notes');
    } catch (e) {
      print('Error fetching notes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredNotes = _notes;
      });
      return;
    }

    try {
      final titleSnapshot = await _database
          .child('notes')
          .orderByChild('title')
          .startAt(query.toLowerCase())
          .endAt('${query.toLowerCase()}\uf8ff')
          .get();

      final idSnapshot = await _database
          .child('notes')
          .orderByKey()
          .startAt(query)
          .endAt('$query\uf8ff')
          .get();

      final searchResults = <Map<String, dynamic>>[];

      if (titleSnapshot.exists) {
        final titleData = Map<String, dynamic>.from(titleSnapshot.value as Map);
        searchResults.addAll(titleData.entries.map((e) {
          final noteData = Map<String, dynamic>.from(e.value);
          noteData['id'] = e.key;
          return noteData;
        }));
      }

      if (idSnapshot.exists) {
        final idData = Map<String, dynamic>.from(idSnapshot.value as Map);
        searchResults.addAll(idData.entries.map((e) {
          final noteData = Map<String, dynamic>.from(e.value);
          noteData['id'] = e.key;
          return noteData;
        }));
      }

      setState(() {
        _filteredNotes = searchResults;
      });
    } catch (e) {
      print('Error searching notes: $e');
    }
  }

  void _joinNote() async {
    final noteId = _noteIdController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final snapshot = await _database.child('notes/$noteId').get();
      if (!snapshot.exists) {
        throw Exception('노트를 찾을 수 없습니다');
      }

      final noteData = snapshot.value as Map<dynamic, dynamic>;
      final isHost = noteData['hostPassword'] == password;
      final isGuest = noteData['guestPassword'] == password;

      if (!isHost && !isGuest) {
        throw Exception('못된 비밀번호입니다');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoteScreen(
            noteId: noteId,
            password: password,
            isHost: isHost,
            username: username,
            noteTitle: noteData['title'] ?? 'Untitled',
          ),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}일 전';
    } else {
      return '${timestamp.year}.${timestamp.month}.${timestamp.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        flexibleSpace: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      'Live Note',
                      style: TextStyle(
                        fontFamily: 'Pacifico',
                        fontSize: 28,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _handleSearch,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            hintText: '노트 ID 또는 제목으로 검색',
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(Icons.search),
                              onPressed: () =>
                                  _handleSearch(_searchController.text),
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
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _notes = [];
            _filteredNotes = [];
          });
          await _fetchNotes();
        },
        child: Container(
          color: Colors.grey[900],
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1200),
              child: CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            color: Colors.grey[850],
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _noteIdController,
                                    decoration: InputDecoration(
                                      labelText: '노트 ID',
                                      prefixIcon: Icon(Icons.note),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  TextField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      labelText: '사용자 이름',
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  TextField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: '비밀번호',
                                      prefixIcon: Icon(Icons.lock),
                                    ),
                                    obscureText: true,
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _joinNote,
                                    child: Text('노트 참여'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            '최근 노트',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            (MediaQuery.of(context).size.width ~/ 250)
                                .clamp(1, 5),
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _filteredNotes.length) {
                            return null;
                          }
                          final note = _filteredNotes[index];
                          final lastModified = note['lastModified'] != null
                              ? _formatTimestamp(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      note['lastModified'] as int))
                              : '수정되지 않음';

                          return Tooltip(
                            message: note['title'] ?? 'No Title',
                            waitDuration: Duration(milliseconds: 500),
                            child: FoldedCard(
                              color: Colors.grey[850]!,
                              foldSize: 24,
                              child: InkWell(
                                onTap: () {
                                  _noteIdController.text = note['id'];
                                  _usernameController.clear();
                                  _passwordController.clear();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        note['title'] ?? 'No Title',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Spacer(),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'ID: ${note['id']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                          Icon(Icons.access_time,
                                              size: 12, color: Colors.grey),
                                          SizedBox(width: 4),
                                          Text(
                                            lastModified,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _filteredNotes.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateNoteScreen(),
            ),
          );
        },
        // icon: Icon(Icons.add),
        label: Text('새 노트'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
