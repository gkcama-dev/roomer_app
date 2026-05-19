import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:roomer/views/main_wrapper.dart';
import 'package:roomer/views/login_screen.dart'; 
import 'package:roomer/views/group_setup_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        
          if (snapshot.hasData) {
           
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  
                  
                  if (userData['groupId'] == null || userData['groupId'] == "") {
                    return const GroupSetupScreen();
                  }
                  
                
                  return const MainWrapper();
                }
                
                return const GroupSetupScreen();
              },
            );
          }
          
          return const LoginScreen();
        },
      ), 
    );
  }
}