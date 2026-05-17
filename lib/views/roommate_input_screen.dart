import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roomer',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF10B981)),
        useMaterial3: true,
      ),
      home: const RoommateInputScreen(),
    );
  }
}

class RoommateInputScreen extends StatefulWidget {
  const RoommateInputScreen({super.key});

  @override
  State<RoommateInputScreen> createState() => _RoommateInputScreenState();
}

class _RoommateInputScreenState extends State<RoommateInputScreen> {
  final List<String> _roommates = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo container: keep original size, reduce only image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: Image.asset(
                      'assets/images/roomer-light-logo.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback icon if image not found
                        return const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 28,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Roomer',
                style: TextStyle(
                  fontSize: 40, 
                  fontWeight: FontWeight.w700, 
                  color: Color(0xFF065F46),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Split expenses smartly.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 50),
              
              // Card for adding roommates
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Roommates',
                        style: TextStyle(
                          fontWeight: FontWeight.w600, 
                          fontSize: 18,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Enter name...',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onSubmitted: (_) => _addRoommate(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              onPressed: _addRoommate,
                              icon: const Icon(Icons.add, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                minimumSize: const Size(52, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Roommate chips
                      if (_roommates.isNotEmpty) ...[
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _roommates.map((name) => Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: const Color(0xFFD1FAE5)),
                            ),
                            child: Chip(
                              label: Text(
                                name,
                                style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w500),
                              ),
                              backgroundColor: Colors.transparent,
                              deleteIcon: const Icon(Icons.close, size: 18, color: Color(0xFF10B981)),
                              onDeleted: () {
                                setState(() {
                                  _roommates.remove(name);
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide.none,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          )).toList(),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          child: Text(
                            'No roommates added yet',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Start Button - exactly like reference
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _roommates.length >= 2 ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  onPressed: _roommates.length >= 2 
                    ? () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExpenseSetupScreen(roommates: _roommates),
                          ),
                        );
                      } 
                    : null, 
                  child: const Text('Start Roomer'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Hint text when less than 2 roommates
              if (_roommates.length < 2 && _roommates.isNotEmpty)
                const Text(
                  'Add at least 2 roommates to continue',
                  style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _addRoommate() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        _roommates.add(_nameController.text.trim());
        _nameController.clear();
      });
    }
  }
}

// Next screen after start button is pressed
class ExpenseSetupScreen extends StatelessWidget {
  final List<String> roommates;
  
  const ExpenseSetupScreen({super.key, required this.roommates});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses', style: TextStyle(color: Color(0xFF065F46))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF065F46)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 80, color: Color(0xFF10B981)),
            const SizedBox(height: 24),
            Text(
              'Welcome, ${roommates.join(", ")}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text('Expense splitting feature coming soon...'),
          ],
        ),
      ),
    );
  }
}