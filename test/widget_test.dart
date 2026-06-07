import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:school_app/database_helper.dart';
import 'package:school_app/secure_storage_service.dart';
import 'package:school_app/student_provider.dart';
import 'package:school_app/splash_screen.dart';

void main() {
  testWidgets('App smoke test loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DatabaseHelper>(create: (_) => DatabaseHelper.instance),
          Provider<SecureStorageService>(create: (_) => SecureStorageService()),
          ChangeNotifierProvider(create: (_) => StudentProvider()),
        ],
        child: MaterialApp(
          home: const SplashScreen(),
        ),
      ),
    );

    expect(find.text('School App'), findsOneWidget);
    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
  });
}
