import 'package:flutter/material.dart';
import '../pages/settings_page.dart';
import '../pages/chapter_page.dart';
import '../pages/calendar_page.dart';
import '../pages/activity_page.dart';
import '../pages/home_feed_page.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 2; // Default to home tab

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
                color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
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
                color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivityPage()));
              },
              child: const CircleAvatar(child: Icon(Icons.person)),
            ),
          )
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavigationItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor ?? (theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.primary),
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor ?? theme.unselectedWidgetColor,
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
  }
}