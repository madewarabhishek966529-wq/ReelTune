import 'package:flutter/material.dart';
import 'package:reeltune/app/constants.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/features/home/home_screen.dart';

class ReelTuneApp extends StatelessWidget {
  const ReelTuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
