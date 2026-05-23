import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // 1. NOTIFICATION SYSTEM INITIALIZE
  Future<void> initNotifications() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: androidSettings);
      await _localNotificationsPlugin.initialize(settings: initializationSettings);
      await saveDeviceToken();
    }
  }

  // 2. SAVE DEVICE FCM TOKEN
  Future<void> saveDeviceToken() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    String? token = await _fcm.getToken();
    if (token != null) {
      await _db.collection('users').doc(currentUser.uid).update({'fcmToken': token});
      print("📱 Live FCM Token Saved: $token");
    }
  }

  // [OAUTH2 ACCESS TOKEN GENERATOR] - service-account.json Make Token 
  Future<String> _getAccessToken() async {
    final String response = await rootBundle.loadString('assets/service-account.json');
    final accountCredentials = ServiceAccountCredentials.fromJson(response);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final AuthClient client = await clientViaServiceAccount(accountCredentials, scopes);
    return client.credentials.accessToken.data;
  }

  // [REAL-TIME DISPATCHER] - Send Push Notification 
  Future<void> sendNotificationToGroup({
    required String groupId,
    required String title,
    required String body,
  }) async {
    try {
      String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      String accessToken = await _getAccessToken();

      final String serviceAccountContent = await rootBundle.loadString('assets/service-account.json');
      final Map<String, dynamic> jsonMap = json.decode(serviceAccountContent);
      final String projectId = jsonMap['project_id'] ?? '';

      DocumentSnapshot groupDoc = await _db.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return;

      List memberIds = (groupDoc.data() as Map<String, dynamic>)['members'] ?? [];

      for (String uid in memberIds) {
        if (uid == currentUid) continue;

        DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>?;
          String? fcmToken = userData?['fcmToken'];

          if (fcmToken != null && fcmToken.isNotEmpty) {
            final String url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
            
            final response = await http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
              body: json.encode({
                'message': {
                  'token': fcmToken,
                  'notification': {
                    'title': title,
                    'body': body,
                  },
                  'android': {
                    'notification': {
                      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                      'sound': 'default',
                    }
                  }
                }
              }),
            );

            if (response.statusCode == 200) {
              print("Notification sent successfully to user: $uid");
            } else {
              print("FCM Send Error: ${response.body}");
            }
          }
        }
      }
    } catch (e) {
      print("🚨 Push Notification Trigger Failed: ${e.toString()}");
    }
  }
}