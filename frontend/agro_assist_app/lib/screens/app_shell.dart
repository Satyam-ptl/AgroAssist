import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'crops_screen.dart';
import 'farmers_screen.dart';
import 'home_screen.dart';
import 'tasks_screen.dart';
import 'weather_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    CropsScreen(),
    FarmersScreen(),
    TasksScreen(),
    WeatherScreen(),
  ];

  List<NavigationDestination> _destinationsForRole() {
    final isFarmer = AuthService.session?.isFarmer == true;
    return [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Crops',
      ),
      NavigationDestination(
        icon: Icon(isFarmer ? Icons.person_outline : Icons.group_outlined),
        selectedIcon: Icon(isFarmer ? Icons.person : Icons.group),
        label: isFarmer ? 'Profile' : 'Farmers',
      ),
      const NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: 'Tasks',
      ),
      const NavigationDestination(
        icon: Icon(Icons.wb_cloudy_outlined),
        selectedIcon: Icon(Icons.wb_cloudy),
        label: 'Weather',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinationsForRole();
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: destinations,
      ),
    );
  }
}
