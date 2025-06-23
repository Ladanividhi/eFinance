
import 'package:eFinance/screens/AddTransaction.dart';
import 'package:eFinance/screens/EditRecord.dart';
import 'package:eFinance/screens/Login.dart';
import 'package:eFinance/screens/Reports.dart';
import 'package:eFinance/screens/SearchScreen.dart';
import 'package:eFinance/screens/Settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/Constants.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? userEmail;
  String? username;

  @override
  void initState() {
    super.initState();
    loadUserDetails();
  }

  Future<void> loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('user_email') ?? 'user@example.com';
      username = prefs.getString('user_name') ?? 'User';
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', false);
    await prefs.remove('user_email');
    await prefs.remove('user_name');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg_color,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primary_color,
        elevation: 0,
        title: Text(
          'Hello, $username!',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        backgroundColor: Colors.grey[100],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: primary_color),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage("assets/images/logo.png"),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    username ?? 'User',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    userEmail ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: Icon(Icons.saved_search, color: primary_color),
              title: const Text(
                'Search',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.add_card,
                color: primary_color,
              ),
              title: const Text(
                'Add Transaction',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTransactionPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: primary_color),
              title: const Text(
                'Reports',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar, color: primary_color),
              title: const Text(
                'Edit Records',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditRecordsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.mobile_screen_share_outlined, color: primary_color,),
              title: const Text(
                'Share Database',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on_rounded, color: primary_color),
              title: const Text(
                'Payment',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: primary_color),
              title: const Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },            ),
            ListTile(
              leading: const Icon(Icons.logout_sharp, color: Colors.redAccent),
              title: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.redAccent),
              ),
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Confirm Sign Out"),
                      content: const Text("Are you sure you want to Sign Out?"),
                      actions: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text("Yes"),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _logout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                                  (Route<dynamic> route) => false,
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/logo.png", height: 100),
              const SizedBox(height: 20),
              Text(
                "Welcome back, $username!",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primary_color,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your financial dashboard is ready",
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
