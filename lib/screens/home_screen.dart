import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/notification_service.dart';
import 'discover_screen.dart';
import 'encounters_screen.dart';
import 'matches_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser myProfile;

  const HomeScreen({super.key, required this.myProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final pending = NotificationNavigation.instance.consumeRequestedTab();
    if (pending != null) _index = pending;
    NotificationNavigation.instance.addListener(_onNotificationTabRequested);
    NotificationService.instance.syncTokenForUser(widget.myProfile.uid);
  }

  @override
  void dispose() {
    NotificationNavigation.instance.removeListener(_onNotificationTabRequested);
    super.dispose();
  }

  void _onNotificationTabRequested() {
    final requested = NotificationNavigation.instance.consumeRequestedTab();
    if (requested != null && mounted) {
      setState(() => _index = requested);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DiscoverScreen(myProfile: widget.myProfile),
      EncountersScreen(myProfile: widget.myProfile),
      MatchesScreen(myProfile: widget.myProfile),
      ProfileScreen(myProfile: widget.myProfile),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department_outlined),
            activeIcon: Icon(Icons.local_fire_department),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt),
            label: 'Encounters',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
