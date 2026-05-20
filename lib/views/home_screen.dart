import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:roomer/services/expense_service.dart';
import 'package:roomer/models/expense_model.dart';
import 'custom_alert.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExpenseService _expenseService = ExpenseService();
  String _groupId = '';
  List<String> _memberIds = [];
  Map<String, String> _memberNames = {}; // Stores UID -> Real Name mapping

  @override
  void initState() {
    super.initState();
    _loadGroupAndMembers(); // Fetch group details on start
  }

  // Get group code, total member IDs, and their real profiles from Firestore
  void _loadGroupAndMembers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        String gid = (userDoc.data() as Map<String, dynamic>)['groupId'] ?? '';
        if (mounted) setState(() => _groupId = gid);

        if (gid.isNotEmpty) {
          DocumentSnapshot groupDoc = await FirebaseFirestore.instance.collection('groups').doc(gid).get();
          if (groupDoc.exists && groupDoc.data() != null) {
            List members = (groupDoc.data() as Map<String, dynamic>)['members'] ?? [];
            if (mounted) setState(() => _memberIds = List<String>.from(members));

            Map<String, String> namesTemp = {};
            for (String uid in members) {
              DocumentSnapshot mDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
              if (mDoc.exists && mDoc.data() != null) {
                namesTemp[uid] = (mDoc.data() as Map<String, dynamic>)['name'] ?? 'Roommate';
              }
            }
            if (mounted) setState(() => _memberNames = namesTemp);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show spinner while fetching critical group configurations
    if (_groupId.isEmpty || _memberNames.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _expenseService.getExpenses(_groupId), // Real-time expense stream listener
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<ExpenseModel> expenses = snapshot.data ?? [];
          
          // Calculations: Core Totals
          double totalSpending = expenses.fold(0.0, (sum, item) => sum + item.amount);
          int totalTransactions = expenses.length;
          int totalMembers = _memberIds.isNotEmpty ? _memberIds.length : 1;
          double perPersonShare = totalSpending / totalMembers;

          // Split Settlement Logic
          Map<String, double> memberBalances = {};
          for (String uid in _memberIds) {
            memberBalances[uid] = 0.0 - perPersonShare;
          }
          for (var exp in expenses) {
            if (memberBalances.containsKey(exp.paidBy)) {
              memberBalances[exp.paidBy] = memberBalances[exp.paidBy]! + exp.amount;
            }
          }

          // Check if everyone's remaining balance is 0
          bool isAllSettled = expenses.isEmpty || memberBalances.values.every((val) => val.toStringAsFixed(1) == "0.0");

          return Column(
            children: [
              // Emerald Green Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, bottom: 25, left: 24, right: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    // Top Branding & Notification Bell Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.asset(
                                'assets/images/roomer-light-logo.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Roomer',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        // Notification Bell Icon Button
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                          onPressed: () {
                            CustomAlert.show(context: context, message: 'Notifications coming soon! 🔔', isSuccess: true);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    const Text('Total Group Spending', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      'LKR ${totalSpending.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Members', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text('$totalMembers', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Transactions', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text('$totalTransactions', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable Body Area
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 💡 Overall Status Header & [NEW POSITION] Room Code Badge Right Below the Green Card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Overall Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        
                        // Room Code Badge - Placed elegantly at the top right of scroll content
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              if (_groupId.isNotEmpty) {
                                await Clipboard.setData(ClipboardData(text: _groupId));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Group code copied to clipboard')),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Code: $_groupId',
                              style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    
                    // Subtitle status line
                    Text(
                      isAllSettled ? 'All settled' : 'Pending balances',
                      style: TextStyle(color: isAllSettled ? Colors.green : Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 15),

                    // 👥 Dynamic Roommate Splitting List view
                    ..._memberIds.map((uid) {
                      String name = _memberNames[uid] ?? 'Roommate';
                      double balance = memberBalances[uid] ?? 0.0;
                      
                      String statusText = 'Settled';
                      String displayAmt = "0.00";
                      Color amtColor = const Color(0xFF1E293B);
                      IconData statusIcon = Icons.check;
                      Color iconColor = Colors.grey;

                      if (balance > 0.1) {
                        statusText = 'Gets back (Lent)';
                        displayAmt = "+${balance.toStringAsFixed(0)}";
                        amtColor = Colors.green;
                        statusIcon = Icons.arrow_upward_rounded;
                        iconColor = Colors.green;
                      } else if (balance < -0.1) {
                        statusText = 'Owes money';
                        displayAmt = balance.toStringAsFixed(0);
                        amtColor = Colors.redAccent;
                        statusIcon = Icons.arrow_downward_rounded;
                        iconColor = Colors.redAccent;
                      }

                      return _buildMemberCard(name, statusText, displayAmt, amtColor, statusIcon, iconColor);
                    }),
                    
                    const SizedBox(height: 25),

                    // Who Owes Who Header Section
                    const Text('Who Owes Who?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 15),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isAllSettled ? Icons.check_circle : Icons.info_outline_rounded, 
                            color: isAllSettled ? const Color(0xFF10B981) : Colors.orange, 
                            size: 40
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isAllSettled ? 'All settled up!' : 'Balances are updated live based on per-person share.', 
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, color: isAllSettled ? const Color(0xFF065F46) : Colors.orange.shade900),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Analytics Placeholder Container
                    const Text('Monthly Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 15),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'Pie Chart Will Appear Here\n(Food vs Bills vs Rent)', 
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Reusable Member Cost Presentation Component
  Widget _buildMemberCard(String name, String status, String amount, Color amtColor, IconData icon, Color iconColor) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF1F5F9),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Text(
          amount,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: amtColor),
        ),
      ),
    );
  }
}