import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/services/usersessiondata.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  UserSessionData userSessionData = UserSessionData();
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), (() async {
      userSessionData.checkUserSession(context);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: Image(image: AssetImage(AppColors.logoPath),width: 250,),
        ),
      ),
    );
  }
}
