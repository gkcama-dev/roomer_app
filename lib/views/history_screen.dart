import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'package:roomer/constants/app_colors.dart';
import 'package:roomer/services/expense_service.dart';
import 'package:roomer/models/expense_model.dart';
import 'package:roomer/widgets/transaction_card.dart'; // Imported the new reusable custom widget

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ExpenseService _expenseService = ExpenseService();
  String _groupId = '';
  Map<String, String> _memberNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupAndMembers();
  }

  // Fetch initial profile properties and member registry maps asynchronously
  void _loadGroupAndMembers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        String gid = (userDoc.data() as Map<String, dynamic>)['groupId']?.toString() ?? '';

        if (gid.isNotEmpty) {
          DocumentSnapshot groupDoc = await FirebaseFirestore.instance.collection('groups').doc(gid).get();
          if (groupDoc.exists && groupDoc.data() != null) {
            List members = (groupDoc.data() as Map<String, dynamic>)['members'] ?? [];

            Map<String, String> namesTemp = {};
            for (String uid in members) {
              DocumentSnapshot mDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
              namesTemp[uid] = mDoc.exists ? (mDoc.data() as Map<String, dynamic>)['name'] ?? 'Roommate' : 'Roommate';
            }

            if (mounted) {
              setState(() {
                _groupId = gid;
                _memberNames = namesTemp;
                _isLoading = false;
              });
            }
          }
        }
      }
    }
  }

  // Remove existing transaction instance record from firestore database
  void _deleteTransaction(String expenseId) async {
    try {
      await FirebaseFirestore.instance.collection('expenses').doc(expenseId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete transaction')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _groupId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Capture the logged in profile signature string for verification
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          StreamBuilder<List<ExpenseModel>>(
            stream: _expenseService.getExpenses(_groupId), 
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }

              List<ExpenseModel> transactions = snapshot.data ?? [];

              if (transactions.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 60, color: AppColors.textGrey),
                        SizedBox(height: 15),
                        Text('No transactions recorded yet!', style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exp = transactions[index];

                      bool isSettleUp = exp.description.toLowerCase().contains('settled up');
                      String formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(exp.createdAt);

                      // Linked the isolated component widget dynamically
                      return TransactionCard(
                        description: exp.description,
                        date: formattedDate,
                        paidBy: exp.paidByName,
                        amount: exp.amount.toStringAsFixed(2),
                        isSettleUp: isSettleUp,
                        memberNamesList: _memberNames.values.toList(),
                        showDeleteButton: exp.paidBy == currentUserId,
                        onDelete: () => _deleteTransaction(exp.id),
                      );
                    },
                    childCount: transactions.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}