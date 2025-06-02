import 'dart:async';

import 'package:badminton_project/data/constant.dart';
import 'package:badminton_project/data/user.dart';
import 'package:badminton_project/view/auth/auth_page.dart';
import 'package:badminton_project/view/group/group_setup_page.dart';
import 'package:badminton_project/view/main/main_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPage();
}

class _IntroPage extends State<IntroPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _checkAndLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildLoadingUI();
          }

          if (snapshot.hasError || snapshot.data == false) {
            return const AlertDialog(
              title: Text(Constant.APP_NAME),
              content: Text('인터넷 연결이 없거나 자동 로그인이 실패했습니다. 로그인 화면으로 이동합니다.', style: TextStyle(fontFamily: 'Maple_L',)),
            );
          }

          return _buildLoadingUI();
        },
      ),
    );
  }

  Widget _buildLoadingUI() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              Constant.APP_NAME,
              style: TextStyle(
                fontSize: 75,
                fontFamily: 'Maple_B',
                color: Colors.white,
              ),
            ),
            Lottie.asset('res/animation/baddy.json', repeat: false),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkAndLogin() async {
    final hasInternet = await _checkInternet();
    if (!hasInternet) return false;

    await _requestNotificationPermission();

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('id');
    final pw = prefs.getString('pw');
    final type = prefs.getString('type');

    if (id == null || pw == null || type == null) {
      Future.delayed(const Duration(seconds: 2), () => Get.off(() => const AuthPage()));
      return true;
    }

    try {
      if (type == SignType.Email.name) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: id, password: pw);
      } else if (type == SignType.Google.name) {
        final googleUser = await GoogleSignIn().signInSilently();

        if (googleUser == null) {
          Future.delayed(const Duration(seconds: 2), () => Get.off(() => const AuthPage()));
          return false;
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final userDoc = await FirebaseFirestore.instance.collection('baddyusers').doc(id).get();
      final name = userDoc.data()?['name'] ?? '';
      final groupId = userDoc.data()?['groupId'] ?? '';

      final user = BaddyUser(email: id, password: pw, name: name, groupId: groupId);
      user.uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      Get.put(user);

      Future.delayed(const Duration(seconds: 2), () {
        if (groupId.isEmpty) {
          Get.off(() => GroupSetupPage(user: user));
        } else {
          Get.off(() => const MainPage());
        }
      });

      return true;
    } catch (e) {
      Future.delayed(const Duration(seconds: 2), () => Get.off(() => const AuthPage()));
      return false;
    }
  }

  Future<bool> _checkInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.mobile || result == ConnectivityResult.wifi;
  }

  Future<void> _requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Notification permission status: ${settings.authorizationStatus}');
  }
}
