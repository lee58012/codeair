import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/user.dart';
import '../main/main_page.dart';

class GroupSetupPage extends StatefulWidget {
  final BaddyUser user;
  const GroupSetupPage({super.key, required this.user});

  @override
  State<GroupSetupPage> createState() => _GroupSetupPageState();
}

class _GroupSetupPageState extends State<GroupSetupPage> {
  final TextEditingController _groupIdController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();

  BaddyUser? _user;

  @override
  void initState() {
    super.initState();

    // 사용자 정보는 build 이후 보장되도록 프레임 뒤로 넘겨서 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _user = widget.user;
      });
    });
  }

  // 그룹 생성
  Future<void> _createGroup() async {
    final groupId = _groupIdController.text.trim();
    if (groupId.isEmpty || _user == null) return;

    final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
    final groupSnap = await groupRef.get();

    if (!groupSnap.exists) {
      await groupRef.set({
        'name': _groupNameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'members': [_user!.email],
      });

      await _updateUserGroup(groupId);
    } else {
      Get.snackbar("오류", "이미 존재하는 그룹 ID입니다.", backgroundColor: Colors.white,);
    }
  }

  // 기존 그룹 참가
  Future<void> _joinGroup() async {
    final groupId = _groupIdController.text.trim();
    if (groupId.isEmpty || _user == null) return;

    final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
    final groupSnap = await groupRef.get();

    if (groupSnap.exists) {
      await groupRef.update({
        'members': FieldValue.arrayUnion([_user!.email])
      });

      await _updateUserGroup(groupId);
    } else {
      Get.snackbar("오류", "존재하지 않는 그룹입니다.", backgroundColor: Colors.white,);
    }
  }

  // Firestore + 앱 상태 업데이트
  Future<void> _updateUserGroup(String groupId) async {
    if (_user == null) return;

    await FirebaseFirestore.instance.collection('baddyusers').doc(_user!.email).update({
      'groupId': groupId,
    });

    _user!.groupId = groupId;

    Get.off(() => const MainPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("그룹 설정", style: TextStyle(fontFamily: 'Maple_L',))),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(labelText: "그룹 이름 (사용자가 볼 이름)"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _groupIdController,
              decoration: const InputDecoration(labelText: "그룹 ID (고유 ID값)"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createGroup,
              child: const Text("새 그룹 생성", style: TextStyle(fontFamily: 'Maple_L',)),
            ),
            ElevatedButton(
              onPressed: _joinGroup,
              child: const Text("기존 그룹 참가", style: TextStyle(fontFamily: 'Maple_L',)),
            ),
          ],
        ),
      ),
    );
  }
}
