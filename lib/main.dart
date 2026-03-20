import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:layz/core/theme/app_theme.dart';
import 'package:layz/features/splash/splash_screen.dart'; // ← changed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // ← add this
      statusBarIconBrightness: Brightness.light, // ← add this
    ),
  );

  // TODO: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const LAYZApp());
}

class LAYZApp extends StatelessWidget {
  const LAYZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAYZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(), // ← changed
    );
  }
}
