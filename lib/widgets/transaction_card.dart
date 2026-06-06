import 'package:flutter/material.dart';
import 'package:roomer/constants/app_colors.dart';

class TransactionCard extends StatelessWidget {
  final String description;
  final String date;
  final String paidBy;
  final String amount;
  final bool isSettleUp;
  final List<String> memberNamesList;
  final bool showDeleteButton;
  final VoidCallback onDelete; // Callback trigger for safety authentication deletion

  const TransactionCard({
    super.key,
    required this.description,
    required this.date,
    required this.paidBy,
    required this.amount,
    required this.isSettleUp,
    required this.memberNamesList,
    required this.showDeleteButton,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSettleUp ? AppColors.secondary.withOpacity(0.1) : AppColors.primary.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSettleUp ? Icons.handshake_rounded : Icons.shopping_bag_rounded, 
                    color: isSettleUp ? AppColors.secondary : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text(date, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.scaffoldBg, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          isSettleUp ? 'Settlement Payment' : 'Paid by $paidBy', 
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LKR $amount', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSettleUp ? AppColors.secondary : AppColors.textDark),
                    ),
                    const SizedBox(height: 5),
                    
                    if (showDeleteButton) 
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, 
                          minimumSize: const Size(50, 30), 
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onDelete, 
                        child: const Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                  ],
                )
              ],
            ),
            
            if (!isSettleUp) ...[
              const Divider(height: 25, color: AppColors.border),
              const Text('Split equally between:', style: TextStyle(color: AppColors.textGrey, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: memberNamesList.map((name) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(name, style: const TextStyle(color: AppColors.textDark, fontSize: 11, fontWeight: FontWeight.bold)),
                )).toList(),
              )
            ]
          ],
        ),
      ),
    );
  }
}