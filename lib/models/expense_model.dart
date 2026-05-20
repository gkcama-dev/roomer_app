import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String description;
  final double amount;
  final String paidBy;     // Paid User ID 
  final String paidByName; // Paid Name
  final String groupId;    // Group ID
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.paidByName,
    required this.groupId,
    required this.createdAt,
  });

  // Firestore -> Map 
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'paidByName': paidByName,
      'groupId': groupId,
      'createdAt': createdAt,
    };
  }

  // Firestore -> Object 
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paidBy: map['paidBy'] ?? '',
      paidByName: map['paidByName'] ?? 'Unknown',
      groupId: map['groupId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}