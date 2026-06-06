import 'package:flutter/material.dart';
import 'package:roomer/constants/app_colors.dart';

class DebtSettlementCard extends StatelessWidget {
  final Map<String, double> memberBalances;
  final Map<String, String> memberNames;

  const DebtSettlementCard({
    super.key,
    required this.memberBalances,
    required this.memberNames,
  });

  @override
  Widget build(BuildContext context) {
    // Separate users into debtors (minus balance) and creditors (plus balance)
    List<MapEntry<String, double>> debtors = [];
    List<MapEntry<String, double>> creditors = [];

    memberBalances.forEach((uid, balance) {
      if (balance < -0.5) {
        debtors.add(MapEntry(uid, balance.abs()));
      } else if (balance > 0.5) {
        creditors.add(MapEntry(uid, balance));
      }
    });

    // Structure list to hold raw data maps instead of single strings
    List<Map<String, dynamic>> settlements = [];

    // Deep copy arrays for manipulation in the matching algorithm
    List<MapEntry<String, double>> tempDebtors = debtors.map((e) => MapEntry(e.key, e.value)).toList();
    List<MapEntry<String, double>> tempCreditors = creditors.map((e) => MapEntry(e.key, e.value)).toList();

    int dIdx = 0;
    int cIdx = 0;

    while (dIdx < tempDebtors.length && cIdx < tempCreditors.length) {
      var debtor = tempDebtors[dIdx];
      var creditor = tempCreditors[cIdx];

      double dAmt = debtor.value;
      double cAmt = creditor.value;
      double minAmt = dAmt < cAmt ? dAmt : cAmt;

      settlements.add({
        'from': memberNames[debtor.key] ?? 'Roommate',
        'to': memberNames[creditor.key] ?? 'Roommate',
        'amount': minAmt,
      });

      tempDebtors[dIdx] = MapEntry(debtor.key, dAmt - minAmt);
      tempCreditors[cIdx] = MapEntry(creditor.key, cAmt - minAmt);

      if (tempDebtors[dIdx].value < 0.5) dIdx++;
      if (tempCreditors[cIdx].value < 0.5) cIdx++;
    }

    if (settlements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 40),
            SizedBox(height: 10),
            Text(
              'All settled up! No pending debts.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Render individual settlement cards dynamically matching split design pattern
    return Column(
      children: settlements.map((settlement) {
        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Circular Avatar Container with Exchange Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 15),
                // Debt Information Text Layout
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Owes',
                        style: TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                          children: [
                            TextSpan(
                              text: settlement['from'],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                            const TextSpan(text: ' ➔ '),
                            TextSpan(
                              text: settlement['to'],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Absolute Right-aligned Currency Metric Frame
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      settlement['amount'].toStringAsFixed(2),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark, letterSpacing: -0.5),
                    ),
                    const Text(
                      'LKR',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}