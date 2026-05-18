import 'package:flutter/material.dart';
import 'views/roommate_input_screen.dart'; 
import 'views/main_wrapper.dart';

void main() {
  runApp(const RoomerApp());
}

class RoomerApp extends StatelessWidget {
  const RoomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roomer',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          primary: const Color(0xFF10B981),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), 
        fontFamily: 'Lato', 
      ),
      home: const MainWrapper(), 
    );
  }
}