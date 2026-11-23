import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'weight_calc_screen.dart';
import 'passport_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    WeightCalcScreen(),
    PassportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1B4332),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Katalog'),
          BottomNavigationBarItem(
            icon: Icon(Icons.scale),
            label: 'Weight Calc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge),
            label: 'Gear Passport',
          ),
        ],
      ),
    );
  }
}
