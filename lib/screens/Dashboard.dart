import 'package:eFinance/db/database_helper.dart';
import 'package:eFinance/screens/AddTransaction.dart';
import 'package:eFinance/screens/EditRecord.dart';
import 'package:eFinance/screens/Login.dart';
import 'package:eFinance/screens/Reports.dart';
import 'package:eFinance/screens/SearchScreen.dart';
import 'package:eFinance/screens/Settings.dart';
import 'package:eFinance/utils/Constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pie_chart/pie_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? userEmail;
  String? username;

  double totalLoan = 0;
  double totalInterest = 0;
  double totalCFBalance = 0;
  double totalWithdrawal = 0;
  double totalCredit = 0;
  double totalBalance = 0;
  int runningCount = 0;
  int closedCount = 0;

  @override
  void initState() {
    super.initState();
    loadUserDetails();
    loadDashboardStats();
  }

  Future<void> loadDashboardStats() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
    SELECT 
      SUM(loan_amount) AS totalLoan,
      SUM(interest) AS totalInterest,
      SUM(cf_balance) AS totalCFBalance,
      SUM(withdrawal_amount) AS totalWithdrawal,
      SUM(credit_amount) AS totalCredit,
      SUM(balance) AS totalBalance,
      (SELECT COUNT(*) FROM transactions WHERE status = 1) AS runningCount,
      (SELECT COUNT(*) FROM transactions WHERE status = 0) AS closedCount
    FROM transactions
  ''');

    if (result.isNotEmpty) {
      final row = result.first;
      setState(() {
        totalLoan = (row['totalLoan'] as num?)?.toDouble() ?? 0;
        totalInterest = (row['totalInterest'] as num?)?.toDouble() ?? 0;
        totalCFBalance = (row['totalCFBalance'] as num?)?.toDouble() ?? 0;
        totalWithdrawal = (row['totalWithdrawal'] as num?)?.toDouble() ?? 0;
        totalCredit = (row['totalCredit'] as num?)?.toDouble() ?? 0;
        totalBalance = (row['totalBalance'] as num?)?.toDouble() ?? 0;
        runningCount = row['runningCount'] as int? ?? 0;
        closedCount = row['closedCount'] as int? ?? 0;
      });
    }
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
  Widget _buildStatCard(String title, String value) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primary_color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDoubleCardRow(String title1, String value1, String title2, String value2) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(title1, value1)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard(title2, value2)),
      ],
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  _buildDoubleCardRow("Total Loan", totalLoan.toStringAsFixed(2), "Total Interest", totalInterest.toStringAsFixed(2)),
                  const SizedBox(height: 10),
                  _buildDoubleCardRow("C/F Balance", totalCFBalance.toStringAsFixed(2), "Withdrawal", totalWithdrawal.toStringAsFixed(2)),
                  const SizedBox(height: 10),
                  _buildDoubleCardRow("Credit", totalCredit.toStringAsFixed(2), "Balance", totalBalance.toStringAsFixed(2)),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                "Transaction Status",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary_color),
              ),
              const SizedBox(height: 10),
              PieChart(
                dataMap: {
                  "Running": runningCount.toDouble(),
                  "Closed": closedCount.toDouble(),
                },
                animationDuration: const Duration(milliseconds: 800),
                chartRadius: MediaQuery.of(context).size.width / 2.2,
                colorList: [primary_color, Colors.grey],
                chartType: ChartType.ring,
                ringStrokeWidth: 32,
                chartValuesOptions: const ChartValuesOptions(
                  showChartValuesInPercentage: true,
                ),
                legendOptions: const LegendOptions(
                  legendPosition: LegendPosition.bottom,
                ),
              ),
            ],
          ),
        )

    );
  }
}
