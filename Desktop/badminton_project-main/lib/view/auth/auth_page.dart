import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badminton_project/data/user.dart';
import 'package:badminton_project/view/auth/email_login_dialog.dart';
import 'package:badminton_project/view/group/group_setup_page.dart';
import 'package:badminton_project/view/main/main_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'dart:math';

import '../../data/constant.dart';
import 'email_dialog.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPage createState() => _AuthPage();
}

class _AuthPage extends State<AuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount!.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential authResult = await FirebaseAuth.instance
        .signInWithCredential(credential);
    final User? user = authResult.user;

    if (user != null) {
      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      final User? currentUser = FirebaseAuth.instance.currentUser;
      assert(user.uid == currentUser!.uid);
      print('signInWithGoogle succeeded: $user');
      _signIn(SignType.Google, user.email!, "");
      return googleSignInAccount;
    }
    return null;
  }

  void _findPassword() async {
    String email = '';
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            '비밀번호 초기화',
            style: TextStyle(color: Colors.black, fontFamily: 'Maple_B'),
          ),
          content: TextFormField(
            style: TextStyle(color: Colors.black, fontFamily: 'Maple_L'),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Maple_L'),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            onChanged: (value) {
              email = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                '취소',
                style: TextStyle(color: Colors.black, fontFamily: 'Maple_L'),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _auth.sendPasswordResetEmail(email: email);
                Get.back();
              },
              child: Text(
                '확인',
                style: TextStyle(color: Colors.black, fontFamily: 'Maple_L'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _signUp(
    SignType type,
    String email,
    String password,
    String name,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      //  Firebase 인증
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = FirebaseAuth.instance.currentUser!.uid;

      //  Firestore 저장
      await FirebaseFirestore.instance.collection('baddyusers').doc(email).set({
        'email': email,
        'fcm': '',
        'signType': type.name,
        'uid': uid,
        'noti': true,
        'groupId': '',
        'name': name,
      }, SetOptions(merge: true));

      final baddyUser = BaddyUser(
        email: email,
        password: password,
        name: name,
        groupId: '',
      );
      baddyUser.uid = uid;

      if (Get.isRegistered<BaddyUser>()) {
        Get.delete<BaddyUser>();
      }
      Get.put(baddyUser); // 이게 등록되지 않으면 Get.find()에서 죽음
      print('BaddyUser Get.put 완료');

      // UI 이동
      setState(() {
        Get.snackbar(
          Constant.APP_NAME,
          '회원가입 성공',
          backgroundColor: Colors.white,
        );
      });

      Get.to(() => GroupSetupPage(user: baddyUser));
    } on FirebaseAuthException catch (e) {
      setState(() {
        Get.snackbar(
          Constant.APP_NAME,
          e.message ?? '회원가입 중 오류 발생',
          backgroundColor: Colors.white,
        );
      });
    }
  }

  //구글 로그인 유저들을 위한 무작위 이름 생성 함수
  String generateRandomName() {
    const base = ['호랭이', '강쥐', '참새', '고양이', '펭귄', '너굴맨', '앵무새', '해달', '찍찍이'];
    final random = Random();
    final pick = base[random.nextInt(base.length)];
    final number = random.nextInt(9999).toString().padLeft(4, '0');
    return '$pick#$number';
  }

  void _signIn(SignType type, String email, String password) async {
    try {
      late User? user;

      if (type == SignType.Email) {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
      } else {
        final googleUser = await googleSignIn.signIn();
        final googleAuth = await googleUser!.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final result = await _auth.signInWithCredential(credential);
        user = result.user;
      }

      Get.snackbar(Constant.APP_NAME, '로그인 성공', backgroundColor: Colors.white);

      final token = await FirebaseMessaging.instance.getToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('id', email);
      await prefs.setString('pw', password);
      await prefs.setString('type', type.name);

      final uid = type == SignType.Email ? _auth.currentUser?.uid : user!.uid;

      final userDoc =
          await FirebaseFirestore.instance
              .collection('baddyusers')
              .doc(email)
              .get();

      //구글 로그인 하는 사람들 이름 생성 안하고 넘어오는 문제 때문에 fetchedName으로 추가함
      final fetchedName = userDoc.data()?['name'];
      final name =
          (fetchedName != null && fetchedName.toString().trim().isNotEmpty)
              ? fetchedName
              : generateRandomName();
      final groupId = userDoc.data()?['groupId'] ?? '';

      final baddyUser = BaddyUser(
        email: email,
        password: password,
        name: name,
        groupId: groupId,
      );
      baddyUser.uid = uid!;

      if (Get.isRegistered<BaddyUser>()) {
        Get.delete<BaddyUser>();
      }
      Get.put(baddyUser);

      await FirebaseFirestore.instance.collection('baddyusers').doc(email).set({
        'email': email,
        'fcm': token,
        'signType': type.name,
        'uid': uid,
        'noti': true,
        'groupId': groupId,
        'name': name,
      }, SetOptions(merge: true)); //덮어쓰기 방지용

      if (groupId == '') {
        Get.to(() => GroupSetupPage(user: baddyUser));
      } else {
        Get.off(() => const MainPage());
      }
    } on FirebaseAuthException catch (e) {
      //로그인 오류 처리
      print('FirebaseAuthException code: ${e.code}');
      print('FirebaseAuthException message: ${e.message}');
      String message;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = '이메일 또는 비밀번호를 확인해주세요.';
          break;
        case 'invalid-email':
          message = '잘못된 이메일 형식입니다.';
          break;
        case 'user-disabled':
          message = '해당 계정은 비활성화되었습니다.';
          break;
        case 'too-many-requests':
          message = '로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요.';
          break;
        case 'operation-not-allowed':
          message = '현재 이 로그인 방식은 사용할 수 없습니다.';
          break;
        default:
          message = '로그인 중 알 수 없는 오류가 발생했습니다.';
          break;
      }
      Get.snackbar(Constant.APP_NAME, message, backgroundColor: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                Constant.APP_NAME,
                style: TextStyle(
                  fontFamily: 'Maple_B',
                  fontSize: 60,
                  color: Colors.white,
                ),
              ),
              Lottie.asset(
                'res/animation/baddy.json',
                repeat: false,
                width: MediaQuery.of(context).size.width / 2,
              ),
              SizedBox(height: 10),
              SignInButton(
                Buttons.email,
                text: "Sign up with Email",
                onPressed: () async {
                  BaddyUser user = await Get.to(() => SignUpWithEmailPage());
                  if (user != null) {
                    _signUp(
                      SignType.Email,
                      user.email,
                      user.password,
                      user.name,
                    );
                  }
                },
              ),
              SizedBox(height: 5),
              SignInButton(
                Buttons.google,
                text: "Sign up with Google",
                onPressed: () async {
                  await signInWithGoogle();
                },
              ),
              SizedBox(height: 30),
              MaterialButton(
                onPressed: () async {
                  BaddyUser user = await Get.to(() => LoginWithEmailPage());
                  if (user != null) {
                    _signIn(SignType.Email, user.email, user.password);
                  }
                },
                child: Text(
                  '이메일로 로그인하기',
                  style: TextStyle(fontFamily: 'Maple_L'),
                ),
                color: Colors.white,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                ),
                onPressed: _findPassword,
                child: Text(
                  '비밀번호 찾기',
                  style: TextStyle(color: Colors.white, fontFamily: 'Maple_L'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
