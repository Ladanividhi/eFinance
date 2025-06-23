import 'dart:io';
import 'package:flutter/material.dart';
import 'package:eFinance/db/database_helper.dart';
import 'package:eFinance/utils/Constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  String? _sortColumn;
  bool _isAscending = true;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final result = List<Map<String, dynamic>>.from(
      await db.query('transactions'),
    );
    setState(() {
      _allTransactions = result;
      _filteredTransactions = List<Map<String, dynamic>>.from(result);
      _isLoading = false;
    });
  }

  void _filterSearchResults(String query) {
    final filtered =
    _allTransactions.where((tx) {
      final name = tx['full_name']?.toString().toLowerCase() ?? '';
      final accNo = tx['account_number']?.toString() ?? '';
      return name.contains(query.toLowerCase()) || accNo.contains(query);
    }).toList();
    setState(() => _filteredTransactions = filtered);
  }

  void _sortBy(String column) {
    setState(() {
      if (_sortColumn == column) {
        _isAscending = !_isAscending;
      } else {
        _sortColumn = column;
        _isAscending = true;
      }

      _filteredTransactions.sort((a, b) {
        final aVal = a[column];
        final bVal = b[column];
        if (aVal == null || bVal == null) return 0;
        if (aVal is num && bVal is num) {
          return _isAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
        }
        return _isAscending
            ? aVal.toString().compareTo(bVal.toString())
            : bVal.toString().compareTo(aVal.toString());
      });
    });
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

  Widget _buildHeaderCell(String label, String columnKey) {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: columnKey.isNotEmpty ? () => _sortBy(columnKey) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (_sortColumn == columnKey)
              Icon(
                _isAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(int index, Map<String, dynamic> tx) {
    final balance = double.tryParse(tx['balance']?.toString() ?? '0') ?? 0;
    final balanceColor = balance == 0 ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _buildCell(tx['account_number']),
          _buildCell(tx['full_name']),
          _buildCell(tx['date']),
          _buildCell(tx['loan_amount']),
          _buildCell(tx['interest']),
          _buildCell(tx['withdrawal_amount']),
          _buildCell(tx['credit_amount']),
          _buildCell(tx['balance'], color: balanceColor),
        ],
      ),
    );
  }

  Widget _buildCell(dynamic value, {Color? color}) {
    return Expanded(
      flex: 1,
      child: Text(
        value?.toString() ?? '',
        style: TextStyle(fontSize: 14, color: color ?? Colors.black),
        textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg_color,
      appBar: AppBar(
        backgroundColor: primary_color,
        title: const Text(
          'Search Transactions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'pdf') _exportToPDF();
            },
            itemBuilder:
                (BuildContext context) => [
                  _buildPopupItem(
                    "Export to PDF",
                    Icons.picture_as_pdf,
                    'pdf',
                  ),
            ],
          ),
        ],
      ),
      body:
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: primary_color, width: 1.5),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSearchResults,
              decoration: const InputDecoration(
                hintText: 'Search by Name or Account No.',
                prefixIcon: Icon(Icons.search, color: primary_color),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                _buildHeaderCell('Acc No', 'account_number'),
                _buildHeaderCell('Name', 'full_name'),
                _buildHeaderCell('Date', 'date'),
                _buildHeaderCell('Amount', 'loan_amount'),
                _buildHeaderCell('Interest', 'interest'),
                _buildHeaderCell('Withdraw', 'withdrawal_amount'),
                _buildHeaderCell('Credit', 'credit_amount'),
                _buildHeaderCell('Balance', 'balance'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTransactions.length,
              itemBuilder: (context, index) {
                return _buildRow(index, _filteredTransactions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
