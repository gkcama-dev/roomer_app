import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:roomer/constants/app_colors.dart'; 
import 'package:roomer/services/expense_service.dart';
import 'package:roomer/models/expense_model.dart';
import 'package:roomer/widgets/roommate_theme_tile.dart'; 
import 'package:roomer/widgets/analytics_chart_card.dart'; 
import 'package:roomer/widgets/debt_settlement_card.dart'; // Imported the new dynamic debt card widget
import 'custom_alert.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExpenseService _expenseService = ExpenseService();
  
  // Local state properties for group and members
  String _groupId = '';
  List<String> _memberIds = [];
  Map<String, String> _memberNames = {};
  bool _isLoadingConfig = true; 

  @override
  void initState() {
    super.initState();
    // Load initial group configuration once when the screen mounts
    _loadInitialGroupDetails(); 
  }

  // Fetch group ID, members, and mapped user names from Firestore
  Future<void> _loadInitialGroupDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String groupId = (userDoc.data() as Map<String, dynamic>)['groupId']?.toString() ?? '';
      if (groupId.isEmpty) return;

      DocumentSnapshot groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
      List memberIds = (groupDoc.data() as Map<String, dynamic>)['members'] ?? [];

      Map<String, String> memberNames = {};
      for (String uid in memberIds) {
        DocumentSnapshot mDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        memberNames[uid] = mDoc.exists ? (mDoc.data() as Map<String, dynamic>)['name'] ?? 'Roommate' : 'Roommate';
      }

      if (mounted) {
        setState(() {
          _groupId = groupId;
          _memberIds = List<String>.from(memberIds);
          _memberNames = memberNames;
          _isLoadingConfig = false; 
        });
      }
    } catch (e) {
      print("Error loading config: $e");
      if (mounted) {
        setState(() {
          _isLoadingConfig = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner only during the initial configuration fetch
    if (_isLoadingConfig) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_groupId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No group configuration found.')),
      );
    }

    return Scaffold(
      body: StreamBuilder<List<ExpenseModel>>(
        // Listen to active realtime streams from expense service
        stream: _expenseService.getExpenses(_groupId), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          List<ExpenseModel> allTransactions = snapshot.data ?? [];
          
          // Separate regular business expenses from payment settlements
          List<ExpenseModel> actualExpenses = allTransactions.where((e) => !e.description.toLowerCase().contains('settled up')).toList();
          List<ExpenseModel> settleUpTransactions = allTransactions.where((e) => e.description.toLowerCase().contains('settled up')).toList();

          // Core total calculations
          double totalSpending = actualExpenses.fold(0.0, (sum, item) => sum + item.amount);
          int totalTransactions = allTransactions.length;
          int totalMembers = _memberIds.isNotEmpty ? _memberIds.length : 1;
          double perPersonShare = totalSpending / totalMembers;

          // Initialize baseline tracking debt map for all roommates
          Map<String, double> memberBalances = {};
          for (String uid in _memberIds) {
            memberBalances[uid] = 0.0 - perPersonShare;
          }

          // Credit users who spent out of pocket
          for (var exp in actualExpenses) {
            if (memberBalances.containsKey(exp.paidBy)) {
              memberBalances[exp.paidBy] = memberBalances[exp.paidBy]! + exp.amount;
            }
          }

          // Calculate continuous realtime debit and credit logic for settlements
          for (var settle in settleUpTransactions) {
            String descLower = settle.description.toLowerCase().trim();

            if (memberBalances.containsKey(settle.paidBy)) {
              memberBalances[settle.paidBy] = memberBalances[settle.paidBy]! + settle.amount;
            }

            for (String uid in _memberIds) {
              String nameLower = (_memberNames[uid] ?? '').toLowerCase().trim();
              if (nameLower.isNotEmpty && descLower.contains('settled up with $nameLower')) {
                memberBalances[uid] = memberBalances[uid]! - settle.amount;
              }
            }
          }

          bool isAllSettled = allTransactions.isEmpty || memberBalances.values.every((val) => val.toStringAsFixed(1) == "0.0" || val.toStringAsFixed(1) == "-0.0");

          return Column(
            children: [
              // Centralized Header UI Layout Linked to AppColors
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, bottom: 25, left: 24, right: 24),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
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
                        const Text('Overall Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              if (_groupId.isNotEmpty) {
                                await Clipboard.setData(ClipboardData(text: _groupId));
                                if (context.mounted) {
                                  CustomAlert.show(context: context, message: 'Group code copied to clipboard! 📋', isSuccess: true);
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
                    Text(
                      isAllSettled ? 'All settled' : 'Pending balances',
                      style: TextStyle(color: isAllSettled ? Colors.green : AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 15),

                    ..._memberIds.map((uid) {
                      String name = _memberNames[uid] ?? 'Roommate';
                      double balance = memberBalances[uid] ?? 0.0;
                      
                      String statusText = 'Settled';
                      String displayAmt = "0.00";
                      Color amtColor = AppColors.textDark;
                      IconData statusIcon = Icons.check;
                      Color iconColor = AppColors.textGrey;

                      if (balance > 0.5) {
                        statusText = 'Gets back (Lent)';
                        displayAmt = "+${balance.toStringAsFixed(0)}";
                        amtColor = Colors.green;
                        statusIcon = Icons.arrow_upward_rounded;
                        iconColor = Colors.green;
                      } else if (balance < -0.5) {
                        statusText = 'Owes money';
                        displayAmt = balance.toStringAsFixed(0);
                        amtColor = AppColors.error;
                        statusIcon = Icons.arrow_downward_rounded;
                        iconColor = AppColors.error;
                      }

                      return RoommateThemeTile(
                        name: name,
                        status: statusText,
                        trailingAmountOrStatus: displayAmt,
                        trailingColor: amtColor,
                        leadingIcon: statusIcon,
                        iconColor: iconColor,
                      );
                    }),
                    
                    const SizedBox(height: 25),
                    const Text('Who Owes Who?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 15),

                    // Embedded the dynamic settlement card panel mapping active debts
                    DebtSettlementCard(
                      memberBalances: memberBalances,
                      memberNames: _memberNames,
                    ),

                    const SizedBox(height: 25),
                    AnalyticsChartCard(expenses: actualExpenses),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}