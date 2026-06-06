import 'package:flutter/material.dart';
import 'package:roomer/constants/app_colors.dart'; 
import 'package:roomer/services/auth_service.dart';
import 'package:roomer/widgets/primary_button.dart'; 
import 'package:roomer/widgets/custom_text_field.dart'; 
import 'main_wrapper.dart';
import 'custom_alert.dart';

class GroupSetupScreen extends StatefulWidget {
  const GroupSetupScreen({super.key});

  @override
  State<GroupSetupScreen> createState() => _GroupSetupScreenState();
}

class _GroupSetupScreenState extends State<GroupSetupScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupCodeController = TextEditingController();
  bool _isLoading = false;

  // Process the generation of a unique group code and persist to Firestore
  void _handleCreateGroup() async {
    if (_groupNameController.text.isEmpty) {
      CustomAlert.show(context: context, message: 'Please enter a boarding or group name', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);
    String? createdCode = await _authService.createGroup(_groupNameController.text);
    setState(() => _isLoading = false);

    if (createdCode != null) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Group Created Successfully'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share this code with your roommates so they can join:'),
                const SizedBox(height: 15),
                SelectableText(
                  createdCode,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 4),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainWrapper()),
                  );
                },
                child: const Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  // Validate the entered 6-digit identifier token to link the user instance
  void _handleJoinGroup() async {
    if (_groupCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group token')),
      );
      return;
    }

    setState(() => _isLoading = true);
    bool success = await _authService.joinGroup(_groupCodeController.text.trim());
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        CustomAlert.show(context: context, message: 'Successfully joined the group', isSuccess: true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } else {
      if (mounted) {
        CustomAlert.show(context: context, message: 'Invalid Group Code. Please try again.', isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roomer Group Setup', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textDark),
            onPressed: () async {
              await _authService.signOut();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Configuration form panel for creating groups
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.add_business_rounded, color: AppColors.primary, size: 28),
                              SizedBox(width: 10),
                              Text('Create a New Boarding Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text('If you are the first person inside the app from your boarding, create a group here.', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                          const SizedBox(height: 20),
                          
                          // CustomTextField applied for Group Name input
                          CustomTextField(
                            controller: _groupNameController,
                            hintText: 'e.g., Boys Room 04 / Api Set eka',
                            prefixIcon: Icons.business_outlined,
                          ),
                          const SizedBox(height: 15),
                          
                          // PrimaryButton applied for Create Group action
                          PrimaryButton(
                            text: 'Create Group',
                            onPressed: _handleCreateGroup,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text('OR', style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Validation form layout for active invitation tokens
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.group_add_rounded, color: AppColors.secondary, size: 28),
                              SizedBox(width: 10),
                              Text('Join an Existing Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text('If your roommate has already created a group, enter that 6-digit code below.', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                          const SizedBox(height: 20),
                          
                          // CustomTextField applied for centered Code Input configuration
                          CustomTextField(
                            controller: _groupCodeController,
                            hintText: '0 0 0 0 0 0',
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            letterSpacing: 4,
                            hintStyle: const TextStyle(fontSize: 18, color: AppColors.textGrey, letterSpacing: 2),
                          ),
                          const SizedBox(height: 15),
                          
                          // PrimaryButton applied for Join Group action
                          PrimaryButton(
                            text: 'Join Group',
                            backgroundColor: AppColors.secondary,
                            onPressed: _handleJoinGroup,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}