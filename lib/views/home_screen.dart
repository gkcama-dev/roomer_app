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

  Future<Map<String, dynamic>> _fetchGroupDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    String groupId = (userDoc.data() as Map<String, dynamic>)['groupId']?.toString() ?? '';
    if (groupId.isEmpty) throw Exception("No group found for user");

    DocumentSnapshot groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
    List memberIds = (groupDoc.data() as Map<String, dynamic>)['members'] ?? [];

    Map<String, String> memberNames = {};
    for (String uid in memberIds) {
      DocumentSnapshot mDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      memberNames[uid] = mDoc.exists ? (mDoc.data() as Map<String, dynamic>)['name'] ?? 'Roommate' : 'Roommate';
    }

    return {
      'groupId': groupId,
      'memberIds': List<String>.from(memberIds),
      'memberNames': memberNames,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchGroupDetails(),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (groupSnapshot.hasError || !groupSnapshot.hasData) {
          return const Scaffold(body: Center(child: Text('Error loading group configuration')));
        }

        final String groupId = groupSnapshot.data!['groupId'];
        final List<String> memberIds = groupSnapshot.data!['memberIds'];
        final Map<String, String> memberNames = groupSnapshot.data!['memberNames'];

        return Scaffold(
          body: StreamBuilder<List<ExpenseModel>>(
            stream: _expenseService.getExpenses(groupId), 
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<ExpenseModel> allTransactions = snapshot.data ?? [];
              
              // 💡 Regular Expenses සහ Settle Up වෙන් කර හඳුනා ගැනීම (Case-Insensitive)
              List<ExpenseModel> actualExpenses = allTransactions.where((e) => !e.description.toLowerCase().contains('settled up')).toList();
              List<ExpenseModel> settleUpTransactions = allTransactions.where((e) => e.description.toLowerCase().contains('settled up')).toList();

              // Core Totals Calculations
              double totalSpending = actualExpenses.fold(0.0, (sum, item) => sum + item.amount);
              int totalTransactions = allTransactions.length;
              int totalMembers = memberIds.isNotEmpty ? memberIds.length : 1;
              double perPersonShare = totalSpending / totalMembers;

              // ทุกคนเริ่มต้นด้วยการติดหนี้ค่าส่วนกลาง
              Map<String, double> memberBalances = {};
              for (String uid in memberIds) {
                memberBalances[uid] = 0.0 - perPersonShare;
              }

              // වියදම් පියවපු අයට ඒ මුදල ප්ලස් කිරීම
              for (var exp in actualExpenses) {
                if (memberBalances.containsKey(exp.paidBy)) {
                  memberBalances[exp.paidBy] = memberBalances[exp.paidBy]! + exp.amount;
                }
              }

              // 💸 [SUPER MATHEMATICAL FIX] - Settle Up Live Debit / Credit Logic
              for (var settle in settleUpTransactions) {
                String descLower = settle.description.toLowerCase().trim();

                // 1. සල්ලි අතින් දුන්න කෙනා (PaidBy): එයාගේ ණය බේරිලා තියෙන නිසා එයාගේ ගිණුමට මුදල එකතු වේ (+).
                if (memberBalances.containsKey(settle.paidBy)) {
                  memberBalances[settle.paidBy] = memberBalances[settle.paidBy]! + settle.amount;
                }

                // 2. සල්ලි ලබාගත්ත කෙනා (ReceivedBy): එයාට සල්ලි ලැබුණු නිසා එයාට තවදුරටත් ලැබෙන්න තියෙන මුදල අඩු වේ (-).
                for (String uid in memberIds) {
                  String nameLower = (memberNames[uid] ?? '').toLowerCase().trim();
                  
                  // "pasan settled up with kalhara" -> විස්තරයේ අගට Kalhara ඉන්නවද කියා වඩාත් ආරක්ෂිතව සසඳයි
                  if (nameLower.isNotEmpty && descLower.contains('settled up with $nameLower')) {
                    memberBalances[uid] = memberBalances[uid]! - settle.amount;
                  }
                }
              }

              bool isAllSettled = allTransactions.isEmpty || memberBalances.values.every((val) => val.toStringAsFixed(1) == "0.0" || val.toStringAsFixed(1) == "-0.0");

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Overall Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  if (groupId.isNotEmpty) {
                                    await Clipboard.setData(ClipboardData(text: groupId));
                                    if (context.mounted) {
                                      CustomAlert.show(context: context, message: 'Group code copied to clipboard! 📋', isSuccess: true);
                                    }
                                  }
                                },
                                child: Text(
                                  'Code: $groupId',
                                  style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        
                        Text(
                          isAllSettled ? 'All settled' : 'Pending balances',
                          style: TextStyle(color: isAllSettled ? Colors.green : Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 15),

                        ...memberIds.map((uid) {
                          String name = memberNames[uid] ?? 'Roommate';
                          double balance = memberBalances[uid] ?? 0.0;
                          
                          String statusText = 'Settled';
                          String displayAmt = "0.00";
                          Color amtColor = const Color(0xFF1E293B);
                          IconData statusIcon = Icons.check;
                          Color iconColor = Colors.grey;

                          // 💡 අගයන් ලස්සනට පෙන්වීමට රවුන්ඩ් අප් කිරීම් (Rounding offset fix)
                          if (balance > 0.5) {
                            statusText = 'Gets back (Lent)';
                            displayAmt = "+${balance.toStringAsFixed(0)}";
                            amtColor = Colors.green;
                            statusIcon = Icons.arrow_upward_rounded;
                            iconColor = Colors.green;
                          } else if (balance < -0.5) {
                            statusText = 'Owes money';
                            displayAmt = balance.toStringAsFixed(0);
                            amtColor = Colors.redAccent;
                            statusIcon = Icons.arrow_downward_rounded;
                            iconColor = Colors.redAccent;
                          }

                          return _buildMemberCard(name, statusText, displayAmt, amtColor, statusIcon, iconColor);
                        }),
                        
                        const SizedBox(height: 25),

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
      },
    );
  }

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