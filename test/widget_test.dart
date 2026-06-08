import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:school_app/core/database/database_helper.dart';
import 'package:school_app/core/services/secure_storage_service.dart';
import 'package:school_app/core/providers/student_provider.dart';
import 'package:school_app/features/auth/presentation/screens/splash_screen.dart';

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
