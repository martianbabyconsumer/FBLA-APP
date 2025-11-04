import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_service.dart';
import 'providers/calendar_provider.dart';
import 'providers/user_provider.dart';
import 'providers/auth_service.dart';
import 'repository/post_repository.dart';
import 'widgets/app_scaffold.dart';
import 'pages/login_page.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize persisted providers before runApp
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  final postRepo = InMemoryPostRepository();
  await postRepo.initialize();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: themeProvider),
      Provider<NotificationService>(
          create: (_) => NotificationService(_scaffoldMessengerKey)),
      // NotificationService depends on the scaffold messenger key below; we'll provide it using a ProxyProvider in the widget tree.
      ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
      ChangeNotifierProvider<PostRepository>.value(value: postRepo),
      ChangeNotifierProvider<CalendarProvider>(
          create: (_) => CalendarProvider()),
      ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
    ],
    child: const FBLAApp(),
  ));
}

class FBLAApp extends StatelessWidget {
  const FBLAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FBLA CONNECT',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: context.watch<ThemeProvider>().currentTheme,
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (!authService.isAuthenticated) return const LoginPage();
          return const AppScaffold();
        },
      ),
    );
  }
}
// main entrypoint complete
