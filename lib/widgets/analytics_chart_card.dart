import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:roomer/constants/app_colors.dart';
import 'package:roomer/models/expense_model.dart';

class AnalyticsChartCard extends StatelessWidget {
  final List<ExpenseModel> expenses;

  const AnalyticsChartCard({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    // 1. Initialize category counters
    double foodTotal = 0;
    double billsTotal = 0;
    double rentTotal = 0;
    double otherTotal = 0;

    // 2. Filter expenses dynamically based on keywords in description
    for (var exp in expenses) {
      String desc = exp.description.toLowerCase();
      if (desc.contains('food') || desc.contains('groceries') || desc.contains('eat') || desc.contains('rice')) {
        foodTotal += exp.amount;
      } else if (desc.contains('bill') || desc.contains('current') || desc.contains('water') || desc.contains('gas')) {
        billsTotal += exp.amount;
      } else if (desc.contains('rent') || desc.contains('room') || desc.contains('advance')) {
        rentTotal += exp.amount;
      } else {
        otherTotal += exp.amount;
      }
    }

    double total = foodTotal + billsTotal + rentTotal + otherTotal;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 20),
            if (total == 0)
              Container(
                height: 140,
                child: Center(
                  child: Text(
                    'No data available to plot chart',
                    style: TextStyle(color: AppColors.textGrey, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              Row(
                children: [
                  // Pie Chart View
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                        sections: [
                          if (foodTotal > 0)
                            PieChartSectionData(
                              color: AppColors.primary,
                              value: foodTotal,
                              title: '${((foodTotal / total) * 100).toStringAsFixed(0)}%',
                              radius: 20,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          if (billsTotal > 0)
                            PieChartSectionData(
                              color: AppColors.secondary,
                              value: billsTotal,
                              title: '${((billsTotal / total) * 100).toStringAsFixed(0)}%',
                              radius: 20,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          if (rentTotal > 0)
                            PieChartSectionData(
                              color: const Color(0xFF3B82F6), // Blue for Rent
                              value: rentTotal,
                              title: '${((rentTotal / total) * 100).toStringAsFixed(0)}%',
                              radius: 20,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          if (otherTotal > 0)
                            PieChartSectionData(
                              color: const Color(0xFF94A3B8), // Slate for Others
                              value: otherTotal,
                              title: '${((otherTotal / total) * 100).toStringAsFixed(0)}%',
                              radius: 20,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 25),
                  // Legend Indicators View
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIndicator(color: AppColors.primary, text: 'Food/Groceries'),
                        _buildIndicator(color: AppColors.secondary, text: 'Room Bills'),
                        _buildIndicator(color: const Color(0xFF3B82F6), text: 'House Rent'),
                        _buildIndicator(color: const Color(0xFF94A3B8), text: 'Other Costs'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator({required Color color, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}