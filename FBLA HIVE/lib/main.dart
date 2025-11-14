import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_service.dart';
import 'providers/calendar_provider.dart';
import 'providers/user_provider.dart';
import 'providers/auth_service.dart';
import 'providers/user_info_service.dart';
import 'providers/app_settings_provider.dart';
import 'repository/post_repository.dart';
import 'repository/notification_repository.dart';
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

  final appSettingsProvider = AppSettingsProvider();
  await appSettingsProvider.initialize();

  final postRepo = InMemoryPostRepository();
  await postRepo.initialize();

  final notificationRepo = InMemoryNotificationRepository();
  await notificationRepo.initialize();
  
  // Inject notification repository into post repository
  postRepo.setNotificationRepository(notificationRepo);
  
  // Clear stale bot notifications (bot likes that don't exist in current session)
  await notificationRepo.clearBotNotifications();
  
  // Seed bot profiles to Firebase
  postRepo.seedBotProfiles();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: themeProvider),
      ChangeNotifierProvider.value(value: appSettingsProvider),
      Provider<NotificationService>(
          create: (_) => NotificationService(_scaffoldMessengerKey)),
      // NotificationService depends on the scaffold messenger key below; we'll provide it using a ProxyProvider in the widget tree.
      ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
      // UserInfoService needs AuthService
      ProxyProvider<AuthService, UserInfoService>(
        update: (context, authService, previous) => UserInfoService(authService),
      ),
      ChangeNotifierProvider<PostRepository>.value(value: postRepo),
      ChangeNotifierProvider<NotificationRepository>.value(value: notificationRepo),
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
    final themeProvider = context.watch<ThemeProvider>();
    
    return MaterialApp(
      title: 'FBLA CONNECT',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: themeProvider.currentTheme,
      builder: (context, child) {
        // Apply text scaling using MediaQuery
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: themeProvider.fontSize,
          ),
          child: child!,
        );
      },
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
