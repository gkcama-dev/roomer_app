import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ADD NEW EXPENSE 
  Future<bool> addExpense(String description, double amount, String groupId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Paid Firestore users 
      DocumentSnapshot userDoc = await _db.collection('users').doc(currentUser.uid).get();
      String userName = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Someone' : 'Someone';

      // New Document Reference ID 
      DocumentReference docRef = _db.collection('expenses').doc();

      ExpenseModel newExpense = ExpenseModel(
        id: docRef.id,
        description: description,
        amount: amount,
        paidBy: currentUser.uid,
        paidByName: userName,
        groupId: groupId,
        createdAt: DateTime.now(),
      );

      // Firestore 'expenses' collection -> Save 
      await docRef.set(newExpense.toMap());
      return true;
    } catch (e) {
      print("Add Expense Error: ${e.toString()}");
      return false;
    }
  }

  // GET GROUP EXPENSES STREAM 
  Stream<List<ExpenseModel>> getExpenses(String groupId) {
    return _db
        .collection('expenses')
        .where('groupId', isEqualTo: groupId) 
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => ExpenseModel.fromMap(doc.data())).toList();
        });
  }
}