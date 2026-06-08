import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_app/core/database/database_helper.dart';
import 'package:school_app/core/services/secure_storage_service.dart';
import 'package:school_app/core/providers/student_provider.dart';
import 'package:school_app/core/services/background_service.dart';
import 'package:school_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:school_app/core/services/logger_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter doirasidagi xatoliklar (UI render va h.k.)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LoggerService.logError(details.exception, details.stack);
  };

  // Asinxron va platform darajasidagi xatoliklar
  PlatformDispatcher.instance.onError = (error, stack) {
    LoggerService.logError(error, stack);
    return true;
  };

  AppBackgroundService.initializeService();
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseHelper>(create: (_) => DatabaseHelper.instance),
        Provider<SecureStorageService>(create: (_) => SecureStorageService()),
        ChangeNotifierProvider(
          create: (_) => StudentProvider()..fetchStudents(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFF4355B9,
          ), // Yanada yorqinroq professional indigo
          brightness: Brightness.light,
          surface: const Color(0xFFFDFBFF),
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: const Color(0xFFF1F3FB), // Material 3 surface tone
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F3FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF4355B9), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4355B9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadowColor: Colors.black.withValues(alpha: 0.1),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF4355B9), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      themeMode: context.watch<StudentProvider>().themeMode,
      home: const SplashScreen(),
    );
  }
}
