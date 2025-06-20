import 'package:eFinance/screens/Dashboard.dart';
import 'package:eFinance/screens/Login.dart';
import 'package:eFinance/screens/SignUp.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    wrapper();
  }
  void wrapper ()
  async {
    await Future.delayed(const Duration(seconds: 3));
    final prefs = await SharedPreferences.getInstance();
    final isRemembered = prefs.getBool('remember_me') ?? false;

    if (isRemembered) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // white background
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
          fit: BoxFit.contain, // keep original aspect ratio, no cut-off
        ),
      ),
    );
  }
}
