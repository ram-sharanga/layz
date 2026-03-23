// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const LayzApp());
}

class LayzApp extends StatelessWidget {
  const LayzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                    'LAYZ',
      theme:                    AppTheme.dark,
      home:                     const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Lock text scale factor — prevents OS font size from breaking layout
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}