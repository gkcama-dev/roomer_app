import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Emerald Green Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: const Column(
              children: [
                Text('Total Group Spending', style: TextStyle(color: Colors.white70, fontSize: 16)),
                SizedBox(height: 8),
                Text(
                  'LKR 0.00',
                  style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Members', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Text('3', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Transactions', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Text('0', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scroll 
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Overall Status Section
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Overall Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text('All settled', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 15),

                // Member Status Cards (Sample Data) 
                _buildMemberCard('Laky', 'Settled', '0.00'),
                _buildMemberCard('Geeth', 'Settled', '0.00'),
                _buildMemberCard('Pramod', 'Settled', '0.00'),
                
                const SizedBox(height: 25),

                // Who Owes Who Section
                const Text('Who Owes Who?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 15),

                // All Settled Up Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1), // 💡 withValues ලෙස නිවැරදි කර ඇත
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF10B981), size: 40),
                      SizedBox(height: 10),
                      Text('All settled up!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // 📊 [NEW FEATURE] Monthly Analytics (Pie Chart Placeholder)
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
                    child: Text('Pie Chart Will Appear Here\n(Food vs Bills vs Rent)', 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Member Card (Widget) 
  Widget _buildMemberCard(String name, String status, String amount) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE2E8F0)), // 👈 බෝඩර් එක දාන නිවැරදි ක්‍රමය
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF1F5F9),
          child: Icon(Icons.check, color: Colors.grey, size: 20),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Text(
          amount,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ),
    );
  }
}