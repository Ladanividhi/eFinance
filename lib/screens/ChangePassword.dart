import 'package:eFinance/db/database_helper.dart';
import 'package:eFinance/screens/Login.dart';
import 'package:eFinance/utils/Constants.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    bool isNew = false,
    bool isConfirm = false,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: primary_color,
        size: 26, // slightly larger for bold feel
      ),
      suffixIcon:
          isNew || isConfirm
              ? IconButton(
                icon: Icon(
                  (isConfirm ? _obscureConfirmPassword : _obscureNewPassword)
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    if (isConfirm) {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    } else {
                      _obscureNewPassword = !_obscureNewPassword;
                    }
                  });
                },
              )
              : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primary_color, width: 2),
        borderRadius: BorderRadius.circular(30),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primary_color, width: 2),
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final newPassword = _newPasswordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (email.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter email")));
        return;
      }
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter valid email address")),
        );
        return;
      }
      if (newPassword.isEmpty || newPassword.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password must be at least 6 letters")),
        );
        return;
      }
      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
        return;
      }

      final user = await DatabaseHelper.instance.getUserByEmail(email);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user found with this email")),
        );
        return;
      }

      final result = await DatabaseHelper.instance.updatePasswordByEmail(
        email,
        newPassword,
      );

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully")),
        );
        _emailController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update password")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: primary_color,
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, bottom: 30),
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 100),
                  const SizedBox(height: 10),
                  const Text(
                    "eFinance",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Developed By : Smart IT Solutions",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration(
                        "Enter Email",
                        Icons.email_outlined,
                      ),
                      validator: (value) {
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: _inputDecoration(
                        "New Password",
                        Icons.lock_outline,
                        isNew: true,
                      ),
                      validator: (value) {
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: _inputDecoration(
                        "Confirm Password",
                        Icons.lock_outline,
                        isConfirm: true,
                      ),
                      validator: (value) {
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _updatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary_color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Update Password",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
