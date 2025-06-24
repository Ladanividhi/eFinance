import 'package:eFinance/db/database_helper.dart';
import 'package:eFinance/screens/AboutUs.dart';
import 'package:eFinance/screens/ChangePassword.dart';
import 'package:eFinance/screens/EditRecord.dart';
import 'package:eFinance/utils/Constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _carryForward() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final lastMonth = prefs.getString('lastCarryForwardMonth');

    if (lastMonth == currentMonth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Carry forward already done this month.")),
      );
      return;
    }

    // Confirm dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Carry Forward Confirmation",
            style: TextStyle(color: primary_color),
          ),
          content: const Text("Are you sure you want to perform carry forward for this month?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary_color),
              onPressed: () async {
                Navigator.of(context).pop();
                final db = await DatabaseHelper.instance.database;

                String q1 = "UPDATE transactions SET cf_balance = balance, withdrawal_amount = 0, credit_amount = 0";
                await db.execute(q1);

                String q2 = "UPDATE transactions SET balance = (withdrawal_amount + cf_balance + interest) - credit_amount";
                await db.execute(q2);

                await prefs.setString('lastCarryForwardMonth', currentMonth);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Carry forward successful.")),
                );
              },
              child: const Text("Yes, Proceed", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primary_color,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: bg_color,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        children: [
          // Edit Records
          _buildSettingsCard(
            context,
            title: 'Carry Forward',
            icon: Icons.edit_note_rounded,
            onTap: () {
              _carryForward();
            },
          ),

          const SizedBox(height: 14),

          // Change Password
          _buildSettingsCard(
            context,
            title: 'Change Password',
            icon: Icons.lock_reset_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
              );
            },
          ),

          const SizedBox(height: 14),

          // About Us
          _buildSettingsCard(
            context,
            title: 'About Us',
            icon: Icons.info_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsPage()),
              );
            },
          ),

          const SizedBox(height: 30),
          // App Version
          Center(
            child: Text(
              'eFinance v1.0.0',
              style: TextStyle(color: Colors.blueGrey[300], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Custom reusable Card widget
  Widget _buildSettingsCard(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      color: bg_color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: primary_color, size: 28),
        title: Text(
          title,
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: primary_color, size: 18),
        onTap: onTap,
      ),
    );
  }
}
