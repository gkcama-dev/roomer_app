import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';
import 'package:roomer/services/notification_service.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> addExpense(
    String description,
    double amount,
    String groupId, {
    String? customPaidBy,
    String? customPaidByName,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      String finalPaidBy = currentUser.uid;
      String finalPaidByName = 'Someone';

      if (customPaidBy == null || customPaidByName == null) {
        DocumentSnapshot userDoc = await _db.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          finalPaidByName = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Someone';
        }
      } else {
        finalPaidBy = customPaidBy;
        finalPaidByName = customPaidByName;
      }

      DocumentReference docRef = _db.collection('expenses').doc();

      ExpenseModel newExpense = ExpenseModel(
        id: docRef.id,
        description: description,
        amount: amount,
        paidBy: finalPaidBy,
        paidByName: finalPaidByName,
        groupId: groupId,
        createdAt: DateTime.now(),
      );

      await docRef.set(newExpense.toMap());

      NotificationService().sendNotificationToGroup(
        groupId: groupId,
        title: '💰 New Boarding Expense!',
        body: '$finalPaidByName added LKR ${amount.toStringAsFixed(2)} for "$description".',
      );

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
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return ExpenseModel.fromMap(data);
          }).toList();
        });
  }
}