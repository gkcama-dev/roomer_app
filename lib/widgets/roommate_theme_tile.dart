import 'package:flutter/material.dart';
import 'package:roomer/constants/app_colors.dart';

class RoommateThemeTile extends StatelessWidget {
  final String name;
  final String status;
  final String trailingAmountOrStatus;
  final Color trailingColor;
  final IconData leadingIcon;
  final Color iconColor;
  final bool isSettingsMode;

  const RoommateThemeTile({
    super.key,
    required this.name,
    required this.status,
    required this.trailingAmountOrStatus,
    required this.trailingColor,
    required this.leadingIcon,
    required this.iconColor,
    this.isSettingsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    String initial = name.isNotEmpty ? name[0].toUpperCase() : 'R';

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: isSettingsMode
            ? CircleAvatar(
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(initial, style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
              )
            : CircleAvatar(
                backgroundColor: AppColors.scaffoldBg,
                child: Icon(leadingIcon, color: iconColor, size: 20),
              ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        subtitle: Text(status, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        trailing: isSettingsMode
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trailingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trailingAmountOrStatus,
                  style: TextStyle(color: trailingColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            : Text(
                trailingAmountOrStatus,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: trailingColor),
              ),
      ),
    );
  }
}