import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../features/home/screens/home_screen.dart';
import '../features/candidate/screens/candidate_list_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/polls/screens/polls_screen.dart';

class MainTabNavigation extends StatefulWidget {
  const MainTabNavigation({super.key});

  @override
  State<MainTabNavigation> createState() => _MainTabNavigationState();
}

class _MainTabNavigationState extends State<MainTabNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const CandidateListScreen(),
    const ChatListScreen(),
    const PollsScreen(),
    //const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0, // Allow pop only when on home tab
      onPopInvoked: (didPop) {
        if (!didPop && _selectedIndex != 0) {
          // If not on home tab, navigate to home tab instead of closing app
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: AppLocalizations.of(context)?.home ?? 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people),
              label: AppLocalizations.of(context)?.candidates ?? 'Candidates',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat),
              label: AppLocalizations.of(context)?.chatRooms ?? 'Chat Rooms',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.poll),
              label: AppLocalizations.of(context)?.polls ?? 'Polls',
            ),
            // BottomNavigationBarItem(
            //   icon: const Icon(Icons.person),
            //   label: AppLocalizations.of(context)?.profile ?? 'Profile',
            // ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}

