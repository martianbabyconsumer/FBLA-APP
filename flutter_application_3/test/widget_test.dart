// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_3/providers/theme_provider.dart';
import 'package:flutter_application_3/repository/post_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_3/main.dart';

void main() {
  testWidgets('Home screen displays app label and sample post', (WidgetTester tester) async {
    // Build our app and trigger a frame. Provide ThemeProvider like main.dart.
    final themeProvider = ThemeProvider();
    // Provide mock SharedPreferences values for tests and initialize the provider
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      await themeProvider.initialize();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<PostRepository>(create: (_) => InMemoryPostRepository()),
        ],
        child: const FBLAApp(),
      ),
    );
    await tester.pumpAndSettle();

  // Verify the centered top label is present (split into two words with colors)
  expect(find.text('FBLA'), findsOneWidget);
  expect(find.text('CONNECT'), findsOneWidget);

    // Verify the sample post title from the demo data is present
    expect(find.text('My dog is pregnant'), findsOneWidget);

    // Verify the bottom navigation home icon exists
    expect(find.byIcon(Icons.home), findsOneWidget);
  });
}
