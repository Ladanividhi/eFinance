import 'package:flutter/material.dart';
import 'package:eFinance/utils/Constants.dart';
import 'package:eFinance/db/database_helper.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    // Fetch transactions
    await _loadTransactions();
    setState(() => _isLoading = false);
  }


  Future<void> _loadTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    setState(() {
      _transactions = result;
      _filteredTransactions = result;
    });
  }

  void _filterSearchResults(String query) {
    final filtered =
        _transactions.where((transaction) {
          final fullName =
              transaction['full_name']?.toString().toLowerCase() ?? '';
          final accountNumber = transaction['account_number']?.toString() ?? '';
          return fullName.contains(query.toLowerCase()) ||
              accountNumber.contains(query);
        }).toList();

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  String formatDate(String date) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  Widget buildTransactionCard(Map<String, dynamic> data) {
    return Card(
      elevation: 6,
      shadowColor: primary_color.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        iconColor: primary_color,
        collapsedIconColor: primary_color,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['full_name'] ?? '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primary_color,
                ),
              ),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.account_box, "Account No", "${data['account_number']}"),
              _buildInfoRow(Icons.currency_rupee, "Loan Amount", "₹${data['loan_amount']}"),
              _buildInfoRow(Icons.account_balance_wallet, "Balance", "₹${data['balance']}"),
              _buildInfoRow(Icons.calendar_today, "Date", formatDate(data['date'])),
            ]
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          const Divider(thickness: 1.2),
          _buildDetailRow(Icons.phone, "Contact No", data['contact_number']),
          _buildDetailRow(Icons.home, "Address", data['address']),
          _buildDetailRow(Icons.percent, "Interest", "₹${data['interest']}"),
          _buildDetailRow(Icons.repeat, "C/F Balance", "₹${data['cf_balance']}"),
          _buildDetailRow(Icons.arrow_circle_up, "Withdrawal", "₹${data['withdrawal_amount']}"),
          _buildDetailRow(Icons.arrow_circle_down, "Credit", "₹${data['credit_amount']}"),
          _buildDetailRow(Icons.group, "Guarantor", data['guarantor_name']),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primary_color),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primary_color),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg_color,
      appBar: AppBar(
        backgroundColor: primary_color,
        title: const Text(
          "Reports",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔄 Circular loading indicator (visible only when loading)
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: primary_color,
                ),
              ),
            ),

          // 🔍 Search Bar
          if (!_isLoading)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: primary_color, width: 1.5),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterSearchResults,
                decoration: InputDecoration(
                  hintText: 'Search by Name or Account No.',
                  prefixIcon: Icon(Icons.search, color: primary_color),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),

          // 📋 Transaction List
          Expanded(
            child: _isLoading
                ? const SizedBox() // Already showing progress above
                : _filteredTransactions.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 70,
                    color: primary_color.withOpacity(0.4),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "No Transactions Found",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Try adding a new transaction.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredTransactions.length,
              itemBuilder: (context, index) {
                return buildTransactionCard(_filteredTransactions[index]);
              },
            ),
          ),

          // 🖨️ Print Button
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary_color,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Print feature coming soon")),
                  );
                },
                icon: const Icon(Icons.print, color: Colors.white),
                label: const Text("Print", style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

}
