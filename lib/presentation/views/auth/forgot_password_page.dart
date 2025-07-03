import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _emailSent
                                ? Colors.green.withOpacity(0.1)
                                : const Color(0xFFD6F36B).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                            size: 40,
                            color: _emailSent ? Colors.green : const Color(0xFFFF7A4D),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _emailSent ? 'Check Your Email' : 'Forgot Password?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _emailSent
                              ? 'We\'ve sent a password reset link to your email address'
                              : 'Don\'t worry! Enter your email and we\'ll send you a reset link',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  if (!_emailSent) ...[
                    // Email Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            label: 'Email Address',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: authViewModel.validateEmail,
                          ),

                          const SizedBox(height: 32),

                          // Reset Password Button
                          CustomButton(
                            text: 'Send Reset Link',
                            isLoading: authViewModel.isBusy,
                            onPressed: () => _handleResetPassword(authViewModel),
                          ),

                          if (authViewModel.hasError) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                authViewModel.errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else ...[
                    // Success State
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Email Sent Successfully!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check your email (${_emailController.text}) for the password reset link.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Resend Button
                    CustomButton(
                      text: 'Resend Email',
                      backgroundColor: Colors.transparent,
                      textColor: Colors.black87,
                      onPressed: () {
                        setState(() {
                          _emailSent = false;
                        });
                      },
                    ),
                  ],

                  const Spacer(),

                  // Back to Login
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Remember your password? ',
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Color(0xFFFF7A4D),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleResetPassword(AuthViewModel authViewModel) async {
    if (!_formKey.currentState!.validate()) return;

    authViewModel.clearError();
    
    final success = await authViewModel.resetPassword(_emailController.text.trim());

    if (success) {
      setState(() {
        _emailSent = true;
      });
    }
  }
}
