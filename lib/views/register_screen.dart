import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roomer/constants/app_colors.dart'; 
import 'package:roomer/services/auth_service.dart';
import 'package:roomer/widgets/primary_button.dart'; 
import 'package:roomer/widgets/custom_text_field.dart'; // Imported the reusable custom input widget
import 'login_screen.dart';
import 'group_setup_screen.dart';
import 'custom_alert.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Process user input parameters and register a new identity profile inside Firebase
  void _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      CustomAlert.show(context: context, message: 'Please fill all fields', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    User? user = await _authService.registerWithEmail(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (user != null) {
      if (mounted) {
        CustomAlert.show(context: context, message: 'Registration Successful!', isSuccess: true);
        
        // Delay execution briefly to let the presentation alert frame render completely
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GroupSetupScreen()),
        );
      }
    } else {
      if (mounted) {
        CustomAlert.show(context: context, message: 'Registration Failed. Email might be already in use.', isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: AppColors.textDark)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo layout asset structural binding
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/roomer-light-logo.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
              Center(
                child: Column(
                  children: [
                    const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 5),
                    const Text('Sign up to start splitting bills with roommates', style: TextStyle(color: AppColors.textGrey)),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              // Linked the isolated input field components dynamically
              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _nameController,
                hintText: 'John Doe',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _emailController,
                hintText: 'name@email.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Minimum 6 characters',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 35),

              PrimaryButton(
                text: 'Sign Up',
                isLoading: _isLoading,
                onPressed: _register,
              ),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: AppColors.textDark)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Login here',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}