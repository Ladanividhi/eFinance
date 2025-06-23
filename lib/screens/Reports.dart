import 'dart:ui' show TextStyle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:eFinance/utils/Constants.dart';
import 'package:eFinance/db/database_helper.dart';

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
  bool _showRunning = true; // true for running, false for closed
  String _currentFilter = 'all'; // values: 'all', 'today', 'yesterday', 'thisMonth', 'selectdate'
  DateTime? _selectedDate; // Store the last picked date

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    await _loadTransactions();
    setState(() => _isLoading = false);
  }

  Future<void> _loadTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'transactions',
      where: 'status = ?',
      whereArgs: [_showRunning ? 1 : 0],
      orderBy: 'date DESC',
    );

    setState(() {
      _currentFilter = 'tillnow';
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
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
            _buildInfoRow(
              Icons.account_box,
              "Account No",
              "${data['account_number']}",
            ),
            _buildInfoRow(
              Icons.currency_rupee,
              "Loan Amount",
              "₹${data['loan_amount']}",
            ),
            _buildInfoRow(
              Icons.account_balance_wallet,
              "Balance",
              "₹${data['balance']}",
            ),
            _buildInfoRow(
              Icons.calendar_today,
              "Date",
              formatDate(data['date']),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        children: [
          const Divider(thickness: 1.2),
          _buildDetailRow(Icons.phone, "Contact No", data['contact_number']),
          _buildDetailRow(Icons.home, "Address", data['address']),
          _buildDetailRow(Icons.percent, "Interest", "₹${data['interest']}"),
          _buildDetailRow(
            Icons.repeat,
            "C/F Balance",
            "₹${data['cf_balance']}",
          ),
          _buildDetailRow(
            Icons.arrow_circle_up,
            "Withdrawal",
            "₹${data['withdrawal_amount']}",
          ),
          _buildDetailRow(
            Icons.arrow_circle_down,
            "Credit",
            "₹${data['credit_amount']}",
          ),
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
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

  PopupMenuItem<String> _buildPopupItem(
    String text,
    IconData icon,
    String value,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: primary_color, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _filterToday() async {
    final db = await DatabaseHelper.instance.database;
    final todayDay = DateTime.now().day.toString();

    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT * FROM transactions
    WHERE substr(date, 1, instr(date, '-') - 1) = ?
      AND status = ?
    ORDER BY date DESC
  ''', [todayDay, _showRunning ? 1 : 0]);

    setState(() {
      _currentFilter = 'today';
      _filteredTransactions = result;
    });
  }

  Future<void> _filterYesterday() async {
    final db = await DatabaseHelper.instance.database;
    final yesterdayDay = DateTime.now().subtract(const Duration(days: 1)).day.toString();

    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT * FROM transactions
    WHERE substr(date, 1, instr(date, '-') - 1) = ?
      AND status = ?
    ORDER BY date DESC
  ''', [yesterdayDay, _showRunning ? 1 : 0]);

    setState(() {
      _currentFilter = 'yesterday';
      _filteredTransactions = result;
    });
  }

  void _filterThisMonth() {
    final today = DateTime.now();
    final int todayDay = today.day;

    setState(() {
      _currentFilter = 'thisMonth';
      _filteredTransactions = _transactions.where((tx) {
        final dateStr = tx['date'];
        DateTime? date;
        try {
          date = DateFormat('dd-MM-yyyy').parse(dateStr);
        } catch (e) {
          return false;
        }

        return date.day >= 1 &&
            date.day <= todayDay &&
            tx['status'] == (_showRunning ? 1 : 0);
      }).toList();
    });
  }

  Future<DateTime?> _pickDate() async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primary_color),
          ),
          child: child!,
        );
      },
    );
  }


  void selectdate(DateTime picked) {
    setState(() {
      _currentFilter = 'selectdate';
      _selectedDate = picked;
      _filteredTransactions = _transactions.where((tx) {
        final dateStr = tx['date'];
        DateTime? date;
        try {
          date = DateFormat('dd-MM-yyyy').parse(dateStr);
        } catch (e) {
          return false;
        }
        return date.day == picked.day &&
            tx['status'] == (_showRunning ? 1 : 0);
      }).toList();
    });
  }

  void _onSelectDatePressed() async {
    if (_selectedDate == null) {
      final picked = await _pickDate();
      if (picked != null) {
        selectdate(picked);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a date to filter.")),
        );
      }
    } else {
      selectdate(_selectedDate!);
    }
  }


  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final formattedDate = "${now.day}-${now.month}-${now.year}";

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Text(
              'Loan Report',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Date: $formattedDate', style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'Acc',
              'Date',
              'Full Name',
              'Loan Amount',
              'Interest',
              'Withdrawal',
              'Credit',
              'Balance',
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration:
            pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellHeight: 30,
            cellAlignments: {
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
              7: pw.Alignment.centerRight,
            },
            data: _filteredTransactions.map((tx) {
              return [
                tx['account_number'] ?? '',
                tx['date'] ?? '',
                tx['full_name'] ?? '',
                tx['loan_amount'].toString(),
                tx['interest'].toString(),
                tx['withdrawal_amount'].toString(),
                tx['credit_amount'].toString(),
                tx['balance'].toString(),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'Total Records: ${_filteredTransactions.length}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    // Show print dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'LoanReport',
    );
  }

  void _applyCurrentFilter() {
    switch (_currentFilter) {
      case 'today':
        _filterToday();
        break;
      case 'yesterday':
        _filterYesterday();
        break;
      case 'thisMonth':
        _filterThisMonth();
        break;
      case 'selectdate':
        if (_selectedDate != null) {
          selectdate(_selectedDate!);
        } else {
          _onSelectDatePressed();
        }
        break;
      case 'tillnow':
        _loadTransactions();
        break;
      default:
        _fetchData();
    }
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            onSelected: (value) {
              setState(() {}); // Force refresh
              switch (value) {
                case 'today':
                  _filterToday();
                  break;
                case 'yesterday':
                  _filterYesterday();
                  break;
                case 'select_date':
                  _selectedDate = null;
                  _onSelectDatePressed();
                  break;
                case 'this_month':
                  _filterThisMonth();
                  break;
                case 'till_now':
                  _loadTransactions();
                  break;
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  _buildPopupItem("Today", Icons.today, 'today'),
                  _buildPopupItem(
                    "Yesterday",
                    Icons.calendar_view_day,
                    'yesterday',
                  ),
                  _buildPopupItem(
                    "Select Date",
                    Icons.date_range,
                    'select_date',
                  ),
                  _buildPopupItem(
                    "This Month",
                    Icons.calendar_month,
                    'this_month',
                  ),
                  _buildPopupItem("Till Now", Icons.history, 'till_now'),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
          // Radio buttons for Running/Closed
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _showRunning,
                  onChanged: (value) {
                    if (value != null && value != _showRunning) {
                      setState(() {
                        _showRunning = value;
                      });
                      _applyCurrentFilter();
                    }
                  },
                  activeColor: primary_color,
                ),

                const Text('Running'),
                const SizedBox(width: 20),
                Radio<bool>(
                  value: false,
                  groupValue: _showRunning,
                  onChanged: (value) {
                    if (value != null && value != _showRunning) {
                      setState(() {
                        _showRunning = value;
                      });
                      _applyCurrentFilter();
                    }
                  },
                  activeColor: primary_color,
                ),

                const Text('Closed'),
              ],
            ),
          ),
          // Transaction List
          Expanded(
            child:
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: primary_color),
                      )
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
                          return buildTransactionCard(
                            _filteredTransactions[index],
                          );
                        },
                      ),
          ),
          // Print Button (unchanged)
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
                  {
                    if (_filteredTransactions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No data available to print.")),
                      );
                    } else {
                      _generatePdfReport();
                    }
                  }
                },
                icon: const Icon(Icons.print, color: Colors.white),
                label: const Text(
                  "Print",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
