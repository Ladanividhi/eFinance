import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:eFinance/utils/Constants.dart';
import 'package:eFinance/db/database_helper.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _showRunning = true;
  String _currentFilter = 'today';
  DateTime? _selectedDate;
  int a = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    await _filterToday();
    setState(() => _isLoading = false);
  }

  Future<void> _loadAllTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT * FROM transactions');
    setState(() {
      _transactions = result;
    });
  }

  Future<void> _filterTillNow() async {
    await _loadAllTransactions();
    final today = DateTime.now();
    final int todayDay = today.day;
    setState(() {
      _currentFilter = 'tillnow';
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

  Future<void> _filterAll() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT * FROM transactions
    WHERE status = ?
    ORDER BY date DESC
  ''', [_showRunning ? 1 : 0]);

    setState(() {
      _currentFilter = 'all';
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

  void selectdate(DateTime picked) async {
    await _loadAllTransactions();
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

        return (date.day >= 1 && date.day <= picked.day) &&
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
  void _applyCurrentFilter() {
    switch (_currentFilter) {
      case 'today':
        a = 0;
        _filterToday();
        break;
      case 'yesterday':
        a = 1;
        _filterYesterday();
        break;
      case 'all':
        a = 4;
        _filterAll();
        break;
      case 'selectdate':
        a = 2;
        if (_selectedDate != null) {
          selectdate(_selectedDate!);
        } else {
          _onSelectDatePressed();
        }
        break;
      case 'tillnow':
        a = 3;
        _filterAll();
        break;
      default:
        _filterToday();
    }
  }
  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final timestamp = DateTime.now();
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final formattedTimestamp =
        "${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year} "
        "${hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}";

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        footer:
            (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  "Generated on $formattedTimestamp",
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromInt(primary_color.value),
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "Page ${context.pageNumber} of ${context.pagesCount}",
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromInt(primary_color.value),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        build:
            (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Image(logoImage, width: 40, height: 40),
              pw.SizedBox(width: 10),
              pw.Text(
                'eFinance',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              'Transaction Report',
              style: pw.TextStyle(fontSize: 16),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              "Acc No",
              "Name",
              "Date",
              "Amount",
              "Interest",
              "Withdraw",
              "Credit",
              "Balance",
            ],
            data:
            _filteredTransactions.map((tx) {
              return [
                tx["account_number"] ?? '',
                tx["full_name"] ?? '',
                tx["date"] ?? '',
                tx["loan_amount"]?.toString() ?? '',
                tx["interest"]?.toString() ?? '',
                tx["withdrawal_amount"]?.toString() ?? '',
                tx["credit_amount"]?.toString() ?? '',
                tx["balance"]?.toString() ?? '',
              ];
            }).toList(),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromInt(primary_color.value),
            ),
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
              6: const pw.FlexColumnWidth(1.5),
              7: const pw.FlexColumnWidth(1.5),
            },
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/transaction_report.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Transaction Report');
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
                case 'all':
                  _filterAll();
                  break;
                case 'till_now':
                  _filterTillNow();
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
                  _buildPopupItem("Till Now", Icons.history, 'till_now'),
                  _buildPopupItem(
                    "All",
                    Icons.calendar_month,
                    'all',
                  ),
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
                      // _generatePdfReport();
                      _exportToPDF();
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
