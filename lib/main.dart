// ignore_for_file: avoid_print
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'background_tasks.dart';
import 'firebase_options.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AndroidAlarmManager.initialize();
    await AndroidAlarmManager.oneShot(
      const Duration(seconds: 5),
      0,
      backgroundTask,
      exact: true,
      wakeup: true,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FB Lite',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0866FF), 
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0866FF),
          foregroundColor: Colors.white,
          elevation: 2, // Thêm bóng nhẹ cho AppBar
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        iconTheme: const IconThemeData(color: Colors.grey),
      ),
    );
  }
}
