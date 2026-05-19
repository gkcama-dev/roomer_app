import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          //Expense Added Success Toast 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Text('Expense added!', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // 💳 History Expense Card (Sample Data)
          _buildHistoryCard(
            category: 'Food',
            date: '5/12/2026',
            paidBy: 'Geeth',
            amount: '600.00',
            splitters: ['Laky', 'Geeth', 'Pramod'],
          ),
          
          _buildHistoryCard(
            category: 'Room Rent',
            date: '5/01/2026',
            paidBy: 'Laky',
            amount: '15,000.00',
            splitters: ['Laky', 'Geeth', 'Pramod'],
          ),
        ],
      ),
    );
  }

  // History Card 
  Widget _buildHistoryCard({
    required String category,
    required String date,
    required String paidBy,
    required String amount,
    required List<String> splitters,
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
                // 🟢 Category Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF10B981)), // කෑම/පොත් සඳහා
                ),
                const SizedBox(width: 15),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: Text('Paid by $paidBy', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black)),
                      ),
                    ],
                  ),
                ),
                // Amount & Delete
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('- $amount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 5),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      onPressed: () {},
                      child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                    )
                  ],
                )
              ],
            ),
            const Divider(height: 30, color: Color(0xFFF1F5F9)),
            // Split Between Section
            const Text('Split between', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: splitters.map((name) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(name, style: const TextStyle(color: Color(0xFF065F46), fontSize: 12, fontWeight: FontWeight.w500)),
              )).toList(),
            )
          ],
        ),
      ),
    );
  }
}