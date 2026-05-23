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

// CREATE NEW GROUP FUNCTION
  Future<String?> createGroup(String groupName) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Random 6-digit Code
      final String groupCode = (100000 + (double.parse((_auth.currentUser!.uid.hashCode % 900000).toString()).toInt() % 900000)).toString();

      // Firestore 'groups' -> collection 
      await _db.collection('groups').doc(groupCode).set({
        'groupName': groupName,
        'groupCode': groupCode,
        'createdBy': currentUser.uid,
        'members': [currentUser.uid], 
        'createdAt': FieldValue.serverTimestamp(),
      });

    
      await _db.collection('users').doc(currentUser.uid).update({
        'groupId': groupCode,
      });

      return groupCode; 
    } catch (e) {
      print("Create Group Error: ${e.toString()}");
      return null;
    }
  }

  // JOIN EXISTING GROUP FUNCTION
  Future<bool> joinGroup(String groupCode) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      
      DocumentSnapshot groupDoc = await _db.collection('groups').doc(groupCode).get();

      if (groupDoc.exists) {
       
        await _db.collection('groups').doc(groupCode).update({
          'members': FieldValue.arrayUnion([currentUser.uid]),
        });

        
        await _db.collection('users').doc(currentUser.uid).update({
          'groupId': groupCode,
        });

        return true; 
      } else {
        return false; 
      }
    } catch (e) {
      print("Join Group Error: ${e.toString()}");
      return false;
    }
  }

}