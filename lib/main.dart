// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'background_tasks.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'router/app_router.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeServices();
  runApp(const MyApp());
}

Future<void> _initializeServices() async {
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
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder:
            (context, themeProvider, child) => MaterialApp(
              title: 'FB Lite',
              debugShowCheckedModeBanner: false,
              theme: ThemeProvider.lightTheme,
              darkTheme: ThemeProvider.darkTheme,
              themeMode: themeProvider.themeMode,
              home: const AuthWrapper(),
            ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAdminStatus(context),
      builder: (context, snapshot) {
        debugPrint('FutureBuilder state: ${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint('FutureBuilder error: ${snapshot.error}');
          return const Scaffold(body: Center(child: Text('Error loading app')));
        }

        final userProvider = Provider.of<UserProvider>(context);

        // Sử dụng AppRouter để lấy router phù hợp
        final router = AppRouter.getRouter(context);

        return MaterialApp.router(
          title: userProvider.useAdminRouter ? 'Admin Panel' : 'FB Lite',
          debugShowCheckedModeBanner: false,
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          themeMode: Provider.of<ThemeProvider>(context).themeMode,
          routerConfig: router,
        );
      },
    );
  }

  Future<bool> _checkAdminStatus(BuildContext context) async {
    try {
      // Sử dụng phương thức trong AppRouter
      await AppRouter.checkAndSetAdminRouter(context);
      return true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }
}
