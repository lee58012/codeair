import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../data/user.dart';

class Player {
  final String uid;
  final String email;
  final String name;
  final String groupId;
  final List<String> recentMatches;
  final int totalGames;
  final int wins;
  final String winRate;

  Player({
    required this.uid,
    required this.email,
    required this.name,
    required this.groupId,
    this.recentMatches = const [],
    this.totalGames = 0,
    this.wins = 0,
    this.winRate = '0.0',
  });

  factory Player.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Player(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '이름없음',
      groupId: data['groupId'] ?? '',
      recentMatches: List<String>.from(data['recentMatches'] ?? []),
      totalGames: data['totalGames'] ?? 0,
      wins: data['wins'] ?? 0,
      winRate: data['winRate']?.toString() ?? '0.0',
    );
  }
}

class RecordPage extends StatefulWidget {
  const RecordPage({Key? key}) : super(key: key);

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  // 상수 정의
  static const String _noNamePlaceholder = '이름없음';
  static const String _player1DefaultText = '플레이어 1';
  static const String _player2DefaultText = '플레이어 2';

  // 상태 변수
  int player1Score = 0;
  int player2Score = 0;
  String? currentMatchId;
  Player? selectedPlayer1;
  Player? selectedPlayer2;
  List<Player> allPlayers = [];
  List<Map<String, int>> scoreHistory = [];

  // Firebase 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final BaddyUser currentUser;

  @override
  void initState() {
    super.initState();
    _initCurrentUser();
  }

  void _initCurrentUser() {
    try {
      currentUser = Get.find<BaddyUser>();
      _initializeUserData();
    } catch (e) {
      print('BaddyUser를 찾을 수 없습니다: $e');
      _navigateBackWithError('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.');
    }
  }

  void _navigateBackWithError(String message) {
    Future.microtask(() {
      Get.back();
      Get.snackbar('오류', message, backgroundColor: Colors.white);
    });
  }

  Future<void> _initializeUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('로그인된 사용자가 없습니다.');
        return;
      }

      await _ensureUserDocument(user);

      if (currentUser.groupId.isNotEmpty) {
        await _loadPlayers();
      } else {
        print('사용자의 그룹 ID가 없습니다. 그룹에 먼저 가입해주세요.');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('그룹에 가입 후 이용해주세요.')));
        }
      }
    } catch (e) {
      print('사용자 초기화 중 오류 발생: $e');
    }
  }

  Future<void> _ensureUserDocument(User user) async {
    final userDoc =
        await _firestore.collection('baddyusers').doc(user.email).get();

    if (!userDoc.exists) {
      await _firestore.collection('baddyusers').doc(user.email).set({
        'email': user.email ?? '',
        'name': user.displayName ?? _noNamePlaceholder,
        'groupId': currentUser.groupId,
        'totalGames': 0,
        'wins': 0,
        'winRate': '0.0',
        'recentMatches': [],
        'createdAt': FieldValue.serverTimestamp(),
        'uid': user.uid,
      });
    }
  }

  Future<void> _loadPlayers() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('baddyusers')
              .where('groupId', isEqualTo: currentUser.groupId)
              .get();

      if (mounted) {
        setState(() {
          allPlayers =
              querySnapshot.docs
                  .map((doc) => Player.fromFirestore(doc))
                  .toList();
        });
      }

      print('로드된 플레이어 수: ${allPlayers.length}');
    } catch (e) {
      print('플레이어 로딩 중 오류 발생: $e');
    }
  }

  // 점수 관련 메서드
  void _incrementScore(int playerNumber) {
    if (currentMatchId == null) return;

    setState(() {
      scoreHistory.add({'player1': player1Score, 'player2': player2Score});

      if (playerNumber == 1) {
        player1Score++;
      } else {
        player2Score++;
      }
    });
    _updateScoreInFirebase();
  }

  void _undoLastScore() {
    if (scoreHistory.isEmpty) return;

    setState(() {
      Map<String, int> lastScore = scoreHistory.removeLast();
      player1Score = lastScore['player1']!;
      player2Score = lastScore['player2']!;
    });
    _updateScoreInFirebase();
  }

  Future<void> _resetMatch() async {
    if (currentMatchId != null && !await _confirmReset()) return;

    setState(() {
      player1Score = 0;
      player2Score = 0;
      scoreHistory.clear();
      currentMatchId = null;
    });
  }

  Future<bool> _confirmReset() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('경기 초기화'),
            content: const Text('현재 진행 중인 경기를 초기화하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('확인'),
              ),
            ],
          ),
    );
    return confirm == true;
  }

  Future<void> _updateScoreInFirebase() async {
    if (currentMatchId == null) return;

    try {
      await _firestore.collection('matches').doc(currentMatchId).update({
        'player1.score': player1Score,
        'player2.score': player2Score,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating score in Firebase: $e');
    }
  }

  // 경기 관련 메서드
  Future<void> _endMatch([bool? player1Wins]) async {
    if (currentMatchId == null) return;

    try {
      bool? isDraw = await _checkForDraw();
      if (isDraw == false) {
        _resetScores();
        return;
      }

      await _updateMatchResult(isDraw);
      await _updatePlayersStats(isDraw);
      await _showMatchResultDialog(isDraw);
    } catch (e) {
      print('Error ending match: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('경기 종료 중 오류가 발생했습니다: $e')));
      }
    }
  }

  Future<bool?> _checkForDraw() async {
    if (player1Score != player2Score) return null;

    return await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('경기 종료'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('최종 스코어: $player1Score - $player2Score'),
                const SizedBox(height: 16),
                const Text('무승부로 처리하시겠습니까?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('무승부'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('재경기'),
              ),
            ],
          ),
    );
  }

  void _resetScores() {
    setState(() {
      player1Score = 0;
      player2Score = 0;
      scoreHistory.clear();
    });
  }

  Future<void> _updateMatchResult(bool? isDraw) async {
    final Map<String, dynamic> commonData = {
      'status': 'completed',
      'endTime': FieldValue.serverTimestamp(),
      'finalScore': {'player1': player1Score, 'player2': player2Score},
    };

    if (isDraw == true) {
      await _firestore.collection('matches').doc(currentMatchId).update({
        ...commonData,
        'isDraw': true,
      });
    } else {
      bool player1Won = player1Score > player2Score;
      await _firestore.collection('matches').doc(currentMatchId).update({
        ...commonData,
        'winner': player1Won ? 'player1' : 'player2',
        'isDraw': false,
      });
    }
  }

  Future<void> _updatePlayersStats(bool? isDraw) async {
    if (selectedPlayer1 == null || selectedPlayer2 == null) return;

    if (isDraw == true) {
      await _updatePlayerStats(
        selectedPlayer1!.email,
        null,
        selectedPlayer2!.name,
      );
      await _updatePlayerStats(
        selectedPlayer2!.email,
        null,
        selectedPlayer1!.name,
      );
    } else {
      bool player1Won = player1Score > player2Score;
      await _updatePlayerStats(
        selectedPlayer1!.email,
        player1Won,
        selectedPlayer2!.name,
      );
      await _updatePlayerStats(
        selectedPlayer2!.email,
        !player1Won,
        selectedPlayer1!.name,
      );
    }
  }

  Future<void> _showMatchResultDialog(bool? isDraw) async {
    if (!context.mounted) return;

    String resultMessage =
        isDraw == true
            ? '무승부!\n최종 스코어: $player1Score - $player2Score'
            : '${player1Score > player2Score ? selectedPlayer1!.name : selectedPlayer2!.name}의 승리!\n'
                '최종 스코어: $player1Score - $player2Score';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: const Text('경기 종료'),
              content: Text(resultMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (mounted) {
                      setState(() {
                        player1Score = 0;
                        player2Score = 0;
                        currentMatchId = null;
                        scoreHistory.clear();
                        selectedPlayer1 = null;
                        selectedPlayer2 = null;
                      });
                    }
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _updatePlayerStats(
    String playerEmail,
    bool? isWinner,
    String opponentName,
  ) async {
    try {
      DocumentReference playerRef = _firestore
          .collection('baddyusers')
          .doc(playerEmail);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot playerDoc = await transaction.get(playerRef);

        if (!playerDoc.exists) {
          await playerRef.set({
            'totalGames': 0,
            'wins': 0,
            'winRate': '0.0',
            'recentMatches': [],
          });
          playerDoc = await transaction.get(playerRef);
        }

        Map<String, dynamic> playerData =
            playerDoc.data() as Map<String, dynamic>;

        int totalGames = (playerData['totalGames'] ?? 0) + 1;
        int wins = (playerData['wins'] ?? 0) + (isWinner == true ? 1 : 0);
        double newWinRate = totalGames > 0 ? (wins / totalGames) * 100 : 0.0;

        List<String> recentMatches = List<String>.from(
          playerData['recentMatches'] ?? [],
        );
        String matchResult =
            isWinner == null
                ? "vs $opponentName 무승부 ($player1Score-$player2Score)"
                : "vs $opponentName ${isWinner ? "승리" : "패배"} ($player1Score-$player2Score)";

        if (recentMatches.length >= 5) {
          recentMatches.removeAt(0);
        }
        recentMatches.add(matchResult);

        transaction.update(playerRef, {
          'totalGames': totalGames,
          'wins': wins,
          'winRate': newWinRate.toStringAsFixed(1),
          'recentMatches': recentMatches,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });

      await _updateMatchStatsInFirestore(isWinner);
    } catch (e) {
      print('Error updating player stats: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('통계 업데이트 중 오류가 발생했습니다: $e')));
      }
    }
  }

  Future<void> _updateMatchStatsInFirestore(bool? isWinner) async {
    await _firestore.collection('matches').doc(currentMatchId).update({
      'player1Stats': {
        'email': selectedPlayer1!.email,
        'name': selectedPlayer1!.name,
        'score': player1Score,
        'isWinner': isWinner,
      },
      'player2Stats': {
        'email': selectedPlayer2!.email,
        'name': selectedPlayer2!.name,
        'score': player2Score,
        'isWinner': isWinner == null ? null : !isWinner,
      },
      'matchDate': FieldValue.serverTimestamp(),
      'groupId': selectedPlayer1!.groupId,
    });
  }

  Future<void> _createNewMatch() async {
    if (!_validatePlayersSelected()) return;

    try {
      await _ensurePlayerDocuments();
      String matchId = await _createMatchInFirestore();

      setState(() {
        currentMatchId = matchId;
        player1Score = 0;
        player2Score = 0;
        scoreHistory.clear();
      });
    } catch (e) {
      print('Error creating new match: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('새 경기 생성 중 오류가 발생했습니다: $e')));
      }
    }
  }

  bool _validatePlayersSelected() {
    if (selectedPlayer1 == null || selectedPlayer2 == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('두 플레이어를 모두 선택해주세요')));
      return false;
    }
    return true;
  }

  Future<void> _ensurePlayerDocuments() async {
    for (String email in [selectedPlayer1!.email, selectedPlayer2!.email]) {
      DocumentSnapshot playerDoc =
          await _firestore.collection('baddyusers').doc(email).get();
      if (!playerDoc.exists) {
        await _firestore.collection('baddyusers').doc(email).set({
          'totalGames': 0,
          'wins': 0,
          'winRate': '0.0',
          'recentMatches': [],
        });
      }
    }
  }

  Future<String> _createMatchInFirestore() async {
    DocumentReference docRef = await _firestore.collection('matches').add({
      'player1': {
        'email': selectedPlayer1!.email,
        'name': selectedPlayer1!.name,
        'groupId': selectedPlayer1!.groupId,
        'score': 0,
      },
      'player2': {
        'email': selectedPlayer2!.email,
        'name': selectedPlayer2!.name,
        'groupId': selectedPlayer2!.groupId,
        'score': 0,
      },
      'startTime': FieldValue.serverTimestamp(),
      'status': 'ongoing',
      'groupId': selectedPlayer1!.groupId,
    });

    return docRef.id;
  }

  Future<void> _selectPlayer(bool isPlayer1) async {
    if (!_canSelectPlayer()) return;

    List<Player> availablePlayers = _getAvailablePlayers(isPlayer1);
    Player? selected = await _showPlayerSelectionDialog(
      isPlayer1,
      availablePlayers,
    );

    if (selected != null) {
      setState(() {
        if (isPlayer1) {
          selectedPlayer1 = selected;
        } else {
          selectedPlayer2 = selected;
        }
      });
    }
  }

  bool _canSelectPlayer() {
    if (currentMatchId != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('경기 중에는 플레이어를 변경할 수 없습니다.')));
      return false;
    }
    return true;
  }

  List<Player> _getAvailablePlayers(bool isPlayer1) {
    return allPlayers.where((player) {
      if (isPlayer1) {
        return player.email != selectedPlayer2?.email &&
            player.name != _noNamePlaceholder;
      } else {
        return player.email != selectedPlayer1?.email &&
            player.name != _noNamePlaceholder;
      }
    }).toList();
  }

  Future<Player?> _showPlayerSelectionDialog(
    bool isPlayer1,
    List<Player> availablePlayers,
  ) {
    return showDialog<Player>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isPlayer1 ? '플레이어 1 선택' : '플레이어 2 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availablePlayers.length,
              itemBuilder: (context, index) {
                final player = availablePlayers[index];
                return ListTile(
                  title: Text(player.name),
                  subtitle: Text(player.email),
                  onTap: () => Navigator.of(context).pop(player),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // UI 관련 메서드
  Widget _buildPlayerScoreCard(
    Player? player,
    int score,
    Color backgroundColor,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                player?.name ??
                    (player == selectedPlayer1
                        ? _player1DefaultText
                        : _player2DefaultText),
                style: const TextStyle(fontSize: 24),
              ),
              Text(player?.email ?? '', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              Text(
                score.toString(),
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSelectionRow() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _selectPlayer(true),
              child: Text(selectedPlayer1?.name ?? '플레이어 1 선택'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _selectPlayer(false),
              child: Text(selectedPlayer2?.name ?? '플레이어 2 선택'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (currentMatchId == null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _createNewMatch,
          child: const Text('경기 시작'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _endMatch,
          child: const Text('경기 종료'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('배드민턴 경기 기록'),
        centerTitle: true,
        actions: [
          if (currentMatchId != null && scoreHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undoLastScore,
              tooltip: '마지막 점수 취소',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetMatch,
            tooltip: '경기 초기화',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPlayerSelectionRow(),
          _buildActionButton(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildPlayerScoreCard(
                    selectedPlayer1,
                    player1Score,
                    Colors.blue.withOpacity(0.3),
                    currentMatchId != null ? () => _incrementScore(1) : null,
                  ),
                ),
                Expanded(
                  child: _buildPlayerScoreCard(
                    selectedPlayer2,
                    player2Score,
                    Colors.red.withOpacity(0.3),
                    currentMatchId != null ? () => _incrementScore(2) : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
