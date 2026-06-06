import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roomer/constants/app_colors.dart'; 
import 'package:roomer/services/auth_service.dart';
import 'package:roomer/views/register_screen.dart';
import 'package:roomer/widgets/primary_button.dart';
import 'package:roomer/widgets/custom_text_field.dart'; // Imported the reusable text field widget
import 'main_wrapper.dart';
import 'custom_alert.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Validate form data and execute firebase authentication sequence
  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      CustomAlert.show(context: context, message: 'Please fill all fields', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);
    
    User? user = await _authService.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (user != null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } else {
      if (mounted) {
        CustomAlert.show(context: context, message: 'Login Failed. Check your email & password.', isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Application branding header assembly
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.primary, 
                        shape: BoxShape.circle
                      ),
                      child: Image.asset(
                        'assets/images/roomer-light-logo.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Welcome to Roomer', 
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)
                    ),
                    const SizedBox(height: 5),
                    const Text('Manage boarding expenses easily', style: TextStyle(color: AppColors.textGrey)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Linked the isolated input field components dynamically
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
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 30),

              PrimaryButton(
                text: 'Login',
                isLoading: _isLoading,
                onPressed: _login,
              ),
              const SizedBox(height: 20),

              // Navigation routing alternative anchor link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: AppColors.textDark)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const RegisterScreen())
                      );
                    },
                    child: const Text(
                      'Register here', 
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}