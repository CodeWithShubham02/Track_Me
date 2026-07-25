import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin/model/user_model.dart';
import 'admin/view/admin_home_screen.dart';
import 'admin/view/login_screen.dart';
import 'user/view/employee_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    checkLogin();
    getUserAttendanceID();
  }
  Future<void> getUserAttendanceID() async {
    final prefs = await SharedPreferences.getInstance();
    final attendance_id = prefs.getString('attendance_id');

    if (attendance_id == null) return null;


  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final attendance_id = prefs.getString('attendance_id');

    await Future.delayed(const Duration(seconds: 2)); // splash delay

    if (attendance_id != null) {

    }
    else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
