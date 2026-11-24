import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'weight_calc_screen.dart';
import 'passport_screen.dart';
import 'account_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    WeightCalcScreen(),
    PassportScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        indicatorColor: const Color(0xFF1B4332).withOpacity(0.15),
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.hiking_outlined),
            selectedIcon: Icon(Icons.hiking, color: Color(0xFF1B4332)),
            label: 'Katalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.scale_outlined),
            selectedIcon: Icon(Icons.scale, color: Color(0xFF1B4332)),
            label: 'Weight Calc',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF1B4332)),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1B4332)),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
