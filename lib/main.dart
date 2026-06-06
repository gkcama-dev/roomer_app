import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomer/constants/app_colors.dart'; // Imported the centralized colors file
import 'package:roomer/views/main_wrapper.dart';
import 'package:roomer/views/login_screen.dart';
import 'package:roomer/views/group_setup_screen.dart';
import 'package:roomer/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  NotificationService notificationService = NotificationService();
  await notificationService.initNotifications();

  runApp(const RoomerApp());
}

class RoomerApp extends StatelessWidget {
  const RoomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roomer',
      debugShowCheckedModeBanner: false,
      // Global application theme pipeline configuration
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Lato',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),
      home: StreamBuilder<User?>(
        // Intercept continuous state signatures for global routing profiles
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            NotificationService().saveDeviceToken();

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (userSnapshot.hasData &&
                    userSnapshot.data != null &&
                    userSnapshot.data!.exists) {
                  var userData = userSnapshot.data!.data() as Map<String, dynamic>?;

                  if (userData != null &&
                      userData['groupId'] != null &&
                      userData['groupId'] != "") {
                    return const MainWrapper(); 
                  }
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