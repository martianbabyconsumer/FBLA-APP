import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../pages/settings_page.dart';
import '../pages/chapter_page.dart';
import '../pages/calendar_page.dart';
import '../pages/activity_page.dart';
import '../pages/notifications_page.dart';
import '../pages/home_feed_page.dart';
import '../utils/page_transitions.dart';
import '../utils/app_typography.dart';
import '../repository/notification_repository.dart';
import '../providers/auth_service.dart';
import 'onboarding_tutorial.dart';
// App scaffold - keep imports minimal

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 2; // Default to home tab
  int _previousIndex = 2; // Track previous tab for slide direction
  bool _showingOnboarding = false;
  
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }
  
  Future<void> _checkOnboarding() async {
    final shouldShow = await OnboardingHelper.shouldShowOnboarding();
    if (shouldShow && mounted) {
      setState(() {
        _showingOnboarding = true;
      });
    }
  }

  Future<bool> _loadNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('enableNotifications') ?? false;
    } catch (_) {
      return false;
    }
  }

  void _onNavigationItemTapped(int index) {
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const SettingsPage();
      case 1:
        return const ChapterPage();
      case 2:
        return const HomeFeedPage();
      case 3:
        return const CalendarPage();
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                1.2, 0, 0, 0, 0, // Red channel (increase contrast)
                0, 1.2, 0, 0, 0, // Green channel
                0, 0, 1.2, 0, 0, // Blue channel
                0, 0, 0, 1, 0,   // Alpha channel
              ]),
              child: Image.asset(
                'assets/images/bee_logo_white.png',
                height: 48,
                width: 48,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.hexagon,
                    size: 48,
                    color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                'FBLA',
                style: AppTypography.appTitle(context),
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                'HIVE',
                style: AppTypography.appTitle(context),
              ),
            ),
          ],
        ),
        actions: [
          // Show notifications button only on home tab and when enabled in prefs
          if (_selectedIndex == 2)
            FutureBuilder<bool>(
              future: _loadNotificationsEnabled(),
              builder: (context, snap) {
                final enabled = snap.data ?? false;
                if (!enabled) return const SizedBox.shrink();
                
                return Consumer2<NotificationRepository, AuthService>(
                  builder: (context, notificationRepo, authService, _) {
                    final userId = authService.user?.uid;
                    final unreadCount = userId != null 
                      ? notificationRepo.getUnreadCount(userId) 
                      : 0;
                    
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          tooltip: 'Notifications',
                          onPressed: () {
                            Navigator.of(context).push(
                                SlidePageRoute(page: const NotificationsPage()));
                          },
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                    SlidePageRoute(page: const ActivityPage()));
              },
              child: CircleAvatar(
                // White circular background with themed person icon inside
                backgroundColor: Colors.white,
                radius: 18,
                child: Icon(
                  Icons.person,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
            ),
          )
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Determine slide direction based on tab position
          // Tabs order: 0=Settings, 1=Chapter, 2=Home, 3=Calendar
          final isMovingRight = _selectedIndex > _previousIndex;
          final offsetBegin = isMovingRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
          
          return SlideTransition(
            position: Tween<Offset>(
              begin: offsetBegin,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (ctx) {
          final unselected = theme
                  .bottomNavigationBarTheme.unselectedItemColor ??
              (theme.brightness == Brightness.dark
                  ? theme.colorScheme.onSurface.withAlpha((0.65 * 255).round())
                  : theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()));
          return IconTheme(
            data: IconThemeData(color: unselected),
            child: BottomNavigationBar(
              key: ValueKey(unselected),
              currentIndex: _selectedIndex,
              onTap: _onNavigationItemTapped,
              type: BottomNavigationBarType.fixed,
              // In dark mode prefer lighter (onSurface) tones for both selected and unselected icons
              selectedItemColor:
                  theme.bottomNavigationBarTheme.selectedItemColor ??
                      (theme.brightness == Brightness.dark
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.primary),
              unselectedItemColor: unselected,
              selectedIconTheme: IconThemeData(
                  color: theme.bottomNavigationBarTheme.selectedItemColor ??
                      (theme.brightness == Brightness.dark
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.primary)),
              unselectedIconTheme: IconThemeData(color: unselected),
              backgroundColor: theme.scaffoldBackgroundColor,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  label: 'Your Chapter',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Calendar',
                ),
              ],
            ),
          );
        },
      ),
        ),
        // Onboarding overlay
        if (_showingOnboarding)
          OnboardingTutorial(
            onComplete: () {
              setState(() {
                _showingOnboarding = false;
              });
            },
          ),
      ],
    );
  }
}
