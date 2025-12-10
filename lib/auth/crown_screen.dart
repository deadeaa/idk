import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showCrown = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _showCrown = !_showCrown;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _showCrown ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Image.asset(
            'assets/images/crown.png',
            width: 100,
            height: 100,
          ),
        ),
      ),
    );
  }
}