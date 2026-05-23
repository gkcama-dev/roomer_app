import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'package:roomer/services/expense_service.dart';
import 'package:roomer/models/expense_model.dart';

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

  // Fetch critical group profile setups first
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

  // DELETE EXPENSE LOGIC FROM FIRESTORE
  void _deleteTransaction(String expenseId) async {
    try {
      await FirebaseFirestore.instance.collection('expenses').doc(expenseId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully! 🧹')),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 💡 [SECURITY FIX] දැනට ලොග් වෙලා ඉන්න සැබෑ පරිශීලකයාගේ UID එක ලබා ගැනීම
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _expenseService.getExpenses(_groupId), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<ExpenseModel> transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 60, color: Colors.grey),
                  SizedBox(height: 15),
                  Text('No transactions recorded yet!', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final exp = transactions[index];

              // Check if this is a settle-up log or a regular expense
              bool isSettleUp = exp.description.toLowerCase().contains('settled up');
              
              // Formatting the date nicely: e.g., May 21, 2026
              String formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(exp.createdAt);

              return _buildHistoryCard(
                expenseId: exp.id,
                description: exp.description,
                date: formattedDate,
                paidBy: exp.paidByName,
                amount: exp.amount.toStringAsFixed(2),
                isSettleUp: isSettleUp,
                memberNamesList: _memberNames.values.toList(),
                // 💡 [SECURITY CHECK] වියදම ඇතුළත් කළ කෙනා සහ දැනට ලොග් වී ඉන්න කෙනා සමාන නම් පමණක් Delete පෙන්වයි
                showDeleteButton: exp.paidBy == currentUserId,
              );
            },
          );
        },
      ),
    );
  }

  // Refactored Reusable History Card Component
  Widget _buildHistoryCard({
    required String expenseId,
    required String description,
    required String date,
    required String paidBy,
    required String amount,
    required bool isSettleUp,
    required List<String> memberNamesList,
    required bool showDeleteButton, // 💡 Parameters එකක් ලෙස එකතු කළා
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Dynamic Colored Icon based on Transaction type
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSettleUp ? const Color(0xFFFFEDD5) : const Color(0xFFE6F4EA), // Orange vs Green
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSettleUp ? Icons.handshake_rounded : Icons.shopping_bag_rounded, 
                    color: isSettleUp ? const Color(0xFFF97316) : const Color(0xFF10B981)
                  ),
                ),
                const SizedBox(width: 15),
                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          isSettleUp ? 'Settlement Payment' : 'Paid by $paidBy', 
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount & Functional Delete Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LKR $amount', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSettleUp ? const Color(0xFFF97316) : const Color(0xFF1E293B))
                    ),
                    const SizedBox(height: 5),
                    
                    // 💡 [SECURITY UI] Deletion අයිතිය තියෙන කෙනාට විතරක් බටන් එක පෙන්වයි, නැත්නම් හංගයි
                    if (showDeleteButton) 
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, 
                          minimumSize: const Size(50, 30), 
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap
                        ),
                        onPressed: () => _deleteTransaction(expenseId), 
                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                  ],
                )
              ],
            ),
            
            // Show split summary line only if it's a shared group expense
            if (!isSettleUp) ...[
              const Divider(height: 25, color: Color(0xFFF1F5F9)),
              const Text('Split equally between:', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: memberNamesList.map((name) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(name, style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold)),
                )).toList(),
              )
            ]
          ],
        ),
      ),
    );
  }
}