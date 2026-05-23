import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomer/services/expense_service.dart';
import 'package:roomer/models/expense_model.dart';
import 'custom_alert.dart'; 

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final ExpenseService _expenseService = ExpenseService();
  bool _isExpense = true;
  bool _isLoading = false;

  // Form Controllers
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _settleAmountController = TextEditingController();

  // Dynamic Group Data
  String _groupId = '';
  List<String> _memberIds = [];
  Map<String, String> _memberNames = {}; 

  // Selections (Stores UIDs)
  String? _selectedPayerId;
  String? _settleFromId;
  String? _settleToId;
  
  final List<String> _selectedSplitterIds = [];

  @override
  void initState() {
    super.initState();
    _loadGroupAndMembers();
  }

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
            
            Map<String, String> namesTemp = {};
            for (String uid in members) {
              DocumentSnapshot mDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
              if (mDoc.exists && mDoc.data() != null) {
                namesTemp[uid] = (mDoc.data() as Map<String, dynamic>)['name'] ?? 'Roommate';
              }
            }

            if (mounted) {
              setState(() {
                _memberIds = List<String>.from(members);
                _memberNames = namesTemp;
                
                _selectedSplitterIds.clear();
                _selectedSplitterIds.addAll(_memberIds);
                
                if (_memberIds.isNotEmpty) {
                  _selectedPayerId = user.uid; 
                  _settleFromId = _memberIds[0];
                  _settleToId = _memberIds.length > 1 ? _memberIds[1] : _memberIds[0];
                }
              });
            }
          }
        }
      }
    }
  }

  // Save Normal Boarding Expense
  void _saveExpense() async {
    if (_descController.text.isEmpty || _amountController.text.isEmpty) {
      CustomAlert.show(context: context, message: 'Please fill all fields', isSuccess: false);
      return;
    }

    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      CustomAlert.show(context: context, message: 'Please enter a valid amount', isSuccess: false);
      return;
    }

    if (_selectedSplitterIds.isEmpty) {
      CustomAlert.show(context: context, message: 'Please select at least one roommate to split with!', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _expenseService.addExpense(
        _descController.text.trim(),
        amount,
        _groupId,
      );

      if (mounted) {
        _descController.clear();
        _amountController.clear();
        
        // Reset selections to include everyone again
        setState(() {
          _selectedSplitterIds.clear();
          _selectedSplitterIds.addAll(_memberIds);
        });

        CustomAlert.show(context: context, message: 'Expense added successfully! 🎉', isSuccess: true);
      }
    } catch (e) {
      if (mounted) CustomAlert.show(context: context, message: 'Failed to add expense', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Save Settle Up Transaction
 void _saveSettleUp() async {
    if (_settleAmountController.text.isEmpty) {
      CustomAlert.show(context: context, message: 'Please enter settlement amount', isSuccess: false);
      return;
    }

    if (_settleFromId == _settleToId) {
      CustomAlert.show(context: context, message: 'Cannot settle money to the same person!', isSuccess: false);
      return;
    }

    double? amount = double.tryParse(_settleAmountController.text);
    if (amount == null || amount <= 0) {
      CustomAlert.show(context: context, message: 'Please enter a valid amount', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String fromName = _memberNames[_settleFromId] ?? 'Someone';
      String toName = _memberNames[_settleToId] ?? 'Someone';

      await _expenseService.addExpense(
        '$fromName settled up with $toName',
        amount,
        _groupId,
        customPaidBy: _settleFromId,       // From User UID
        customPaidByName: fromName,        // From User Real Name
      );

      if (mounted) {
        _settleAmountController.clear();
        CustomAlert.show(context: context, message: 'Payment recorded successfully! 💸', isSuccess: true);
      }
    } catch (e) {
      if (mounted) CustomAlert.show(context: context, message: 'Failed to record payment', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_groupId.isEmpty || _memberNames.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isExpense = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isExpense ? const Color(0xFF10B981) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Expense',
                            style: TextStyle(
                              color: _isExpense ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isExpense = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isExpense ? const Color(0xFFF97316) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Settle Up',
                            style: TextStyle(
                              color: !_isExpense ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            _isLoading 
                ? const Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())
                : (_isExpense ? _buildExpenseForm() : _buildSettleUpForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseForm() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                hintText: 'Groceries, Gas bill, Rice packet...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Amount (LKR)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Who Paid?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPayerId,
                  isExpanded: true,
                  items: _memberIds.map((String uid) {
                    return DropdownMenuItem<String>(
                      value: uid,
                      child: Text(_memberNames[uid] ?? 'Roommate', style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() => _selectedPayerId = newValue);
                  },
                ),
              ),
            ),
            const SizedBox(height: 22),

            // 💡 [NEW IMPLEMENTATION] - Interactive "Split Between" Roommates Selector List
            const Text('Split Between', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _memberIds.map((uid) {
                final String name = _memberNames[uid] ?? 'Roommate';
                final bool isSelected = _selectedSplitterIds.contains(uid);
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        if (_selectedSplitterIds.length > 1) {
                          _selectedSplitterIds.remove(uid);
                        }
                      } else {
                        _selectedSplitterIds.add(uid);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE6F4EA) : Colors.white, // Selected නම් ලා කොළ පාටයි
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0), // Selected නම් තද කොළ Border එකක්
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(color: const Color(0xFF10B981).withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                      ] : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF065F46) : const Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: _saveExpense,
                child: const Text('Add Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettleUpForm() {
    return Card(
      color: Colors.white,
      elevation: 0,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('From', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _settleFromId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: _memberIds.map((uid) => DropdownMenuItem(value: uid, child: Text(_memberNames[uid] ?? 'Roommate'))).toList(),
                        onChanged: (val) => setState(() => _settleFromId = val),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 25, left: 8, right: 8),
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.orange),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('To', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _settleToId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: _memberIds.map((uid) => DropdownMenuItem(value: uid, child: Text(_memberNames[uid] ?? 'Roommate'))).toList(),
                        onChanged: (val) => setState(() => _settleToId = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Amount Paid (LKR)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            TextField(
              controller: _settleAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316), 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: _saveSettleUp,
                child: const Text('Record Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}