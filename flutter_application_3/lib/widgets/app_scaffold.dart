import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/settings_page.dart';
import '../pages/chapter_page.dart';
import '../pages/calendar_page.dart';
import '../pages/activity_page.dart';
import '../pages/notifications_page.dart';
import '../pages/home_feed_page.dart';
// App scaffold - keep imports minimal

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 2; // Default to home tab

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FBLA',
              style: TextStyle(
                color: theme.appBarTheme.foregroundColor ??
                    theme.colorScheme.onPrimary,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'CONNECT',
              style: TextStyle(
                color: theme.appBarTheme.foregroundColor ??
                    theme.colorScheme.onPrimary,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.6,
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
                return IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const NotificationsPage()));
                  },
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ActivityPage()));
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
      body: _buildBody(),
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
    );
  }
}
