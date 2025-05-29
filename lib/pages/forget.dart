<<<<<<< HEAD
// forgot_password_screen.dart
import 'package:flutter/material.dart';
=======
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
>>>>>>> 1c92d99cd81646824f609e845f6fd8677a4b0bc1

class ForgetPage extends StatelessWidget {
  const ForgetPage({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password")),
=======
    final emailController = TextEditingController();

    Future<void> _resetPassword() async {
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
>>>>>>> 1c92d99cd81646824f609e845f6fd8677a4b0bc1
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
<<<<<<< HEAD
            Text("Enter your email to reset password"),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(labelText: "Email"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text("Send Reset Link"),
=======
            const Text("Enter your email to reset password"),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child: const Text("Send Reset Link"),
>>>>>>> 1c92d99cd81646824f609e845f6fd8677a4b0bc1
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 1c92d99cd81646824f609e845f6fd8677a4b0bc1
