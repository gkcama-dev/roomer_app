import 'package:flutter/material.dart';
import 'package:roomer/constants/app_colors.dart'; // Imported the centralized colors file
import 'package:roomer/services/auth_service.dart';
import 'home_screen.dart'; 
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0; 

  // Initialize and persist stateful screen configurations inside the wrapper layout
  final List<Widget> _screens = [
    const HomeScreen(),             
    const AddTransactionScreen(),   
    const HistoryScreen(),          
    const SettingsScreen(),         
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Maintain state and prevent rendering latency across navigation transitions
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // Navigation structural controller binding
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; 
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary, // Linked to central AppColors primary theme
        unselectedItemColor: AppColors.textGrey, // Linked to central grey placeholder color
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_rounded), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.history_toggle_off_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}