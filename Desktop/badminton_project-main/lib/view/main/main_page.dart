import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badminton_project/view/auth/auth_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/user.dart';
import 'record_page.dart';
import 'map_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    final BaddyUser currentUser = Get.find();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${currentUser.name}님 안녕하세요!',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Maple_B',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            currentUser.groupId.isEmpty
                ? const Text(
                  "소속 그룹 없음",
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Maple_L',
                  ),
                )
                : FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('groups')
                          .doc(currentUser.groupId)
                          .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        "소속 불러오는 중...",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Maple_L',
                        ),
                      );
                    }
                    if (!snapshot.hasData ||
                        !snapshot.data!.exists ||
                        snapshot.data!.data() == null) {
                      return const Text(
                        "소속 정보 없음",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Maple_L',
                        ),
                      );
                    }

                    final data = snapshot.data!.data();
                    if (data == null) {
                      return const Text(
                        "소속 정보 없음",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Maple_L',
                        ),
                      );
                    }
                    final groupData = data as Map<String, dynamic>;
                    return Text(
                      '소속: ${groupData['name'] ?? '소속 정보 없음'}',
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.white70,
                        fontFamily: 'Maple_L',
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 그룹명 불러오기
            FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('groups')
                      .doc(currentUser.groupId)
                      .get(),
              builder: (context, groupSnapshot) {
                if (!groupSnapshot.hasData || !groupSnapshot.data!.exists) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "그룹 정보를 불러올 수 없습니다.",
                      style: TextStyle(fontFamily: 'Maple_L'),
                    ),
                  );
                }

                final groupData =
                    groupSnapshot.data!.data() as Map<String, dynamic>?;
                final groupName = groupData?['name'] ?? '알 수 없는 그룹';

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "$groupName 회원 명단",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Maple_L',
                    ),
                  ),
                );
              },
            ),

            // 회원 리스트랑 리프레시 기능
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // setstate만 호출해도 StreamBuilder가 새로 build 됨(최신 데이터가 도착했든 아니든 한번 새로 그림)
                  setState(() {});
                },
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      currentUser.groupId.isEmpty
                          ? const Stream.empty()
                          : FirebaseFirestore.instance
                              .collection('baddyusers')
                              .where('groupId', isEqualTo: currentUser.groupId)
                              .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = snapshot.data!.docs;

                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          "그룹에 등록된 사용자가 없습니다.",
                          style: TextStyle(fontFamily: 'Maple_L'),
                        ),
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(
                            user['name'] ?? '알 수 없음',
                            style: const TextStyle(
                              fontSize: 20,
                              fontFamily: 'Maple_B',
                            ),
                          ),
                          onTap: () {
                            final data =
                                user.data() as Map<String, dynamic>? ?? {};
                            final name = data['name'] ?? '알 수 없음';
                            final winRate =
                                data['winRate']?.toString() ?? '정보 없음';
                            final totalGames =
                                data['totalGames']?.toString() ?? '0';
                            final wins = data['wins']?.toString() ?? '0';
                            final recentMatches =
                                data['recentMatches'] as List<dynamic>? ?? [];

                            showDialog(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: Text(
                                      '$name의 전적',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'Maple_B',
                                      ),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "총 게임: $totalGames",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontFamily: 'Maple_L',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "승리: $wins",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontFamily: 'Maple_L',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "승률: $winRate%",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontFamily: 'Maple_L',
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "최근 경기:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Maple_B',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...recentMatches
                                            .map(
                                              (match) => Text(match.toString()),
                                            )
                                            .toList(),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('닫기'),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed, // 아이콘 색 고정할라고
        selectedLabelStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'Maple_L',
        ),
        unselectedLabelStyle: TextStyle(
          color: Colors.white54,
          fontFamily: 'Maple_L',
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: '경기기록',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: '로그아웃'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Get.offAll(() => MainPage());
              break;
            case 1:
              Get.to(() => RecordPage());
              break;
            case 2:
              Get.to(() => MapPage());
              break;
            case 3:
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text(
                        "로그아웃",
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Maple_B',
                        ),
                      ),
                      content: const Text(
                        "로그아웃 하시겠습니까?",
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Maple_L',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "아니오",
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Maple_B',
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();

                            try {
                              await GoogleSignIn().signOut(); // 구글 로그아웃 병행했다면
                            } catch (_) {}

                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear(); // 저장된 로그인 정보 제거

                            Get.offAll(() => const AuthPage());
                          },
                          child: const Text(
                            "예",
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Maple_L',
                            ),
                          ),
                        ),
                      ],
                    ),
              );
              break;
          }
        },
      ),
    );
  }
}
