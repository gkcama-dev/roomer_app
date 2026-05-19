import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// If the external UserModel import is missing in the project, provide a
// minimal local implementation to prevent 'Undefined class UserModel'
// errors. Remove this local class if the real model exists at
// 'package:roomer/models/user_model.dart'.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? groupId;

  UserModel({required this.uid, required this.name, required this.email, this.groupId});

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'groupId': groupId,
      };
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // REGISTER FUNCTION 
  Future<User?> registerWithEmail(String name, String email, String password) async {
    try {
      // Firebase Auth 
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      User? user = result.user;

      if (user != null) {
        
        UserModel newUser = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          groupId: null, 
        );

        await _db.collection('users').doc(user.uid).set(newUser.toMap());
      }
      return user;
    } catch (e) {
      print("Register Error: ${e.toString()}");
      return null;
    }
  }

  // LOGIN FUNCTION 
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return result.user;
    } catch (e) {
      print("Login Error: ${e.toString()}");
      return null;
    }
  }

  // SIGN OUT FUNCTION
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Sign Out Error: ${e.toString()}");
    }
  }

  // CURRENT USER STREAM 
  Stream<User?> get userStream {
    return _auth.authStateChanges();
  }
}