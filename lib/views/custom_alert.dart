import 'dart:ui'; 
import 'package:flutter/material.dart';

class CustomAlert {
  static void show({
    required BuildContext context,
    required String message,
    bool isSuccess = true,
  }) {
   
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 90, 
          left: 20,
          right: 20,
        ),
        duration: const Duration(seconds: 2),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                
                color: isSuccess 
                    ? const Color(0xFF10B981).withOpacity(0.15) 
                    : const Color(0xFFEF4444).withOpacity(0.15), 
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // 🟢 Left Indicator Glow Icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSuccess 
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : const Color(0xFFEF4444).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_rounded : Icons.error_outline_rounded,
                      color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // 📝 Message Text
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                       
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Lato',
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}