import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgetPage extends StatelessWidget {
  const ForgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

    Future<void> resetPassword() async {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: emailController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset email sent. Check your inbox."),
          ),
        );
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Error sending reset email")),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Enter your email to reset password"),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: resetPassword,
              child: const Text("Send Reset Link"),
            ),
          ],
        ),
      ),
    );
  }
}
