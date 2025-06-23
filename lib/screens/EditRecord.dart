import 'package:eFinance/db/database_helper.dart';
import 'package:eFinance/utils/Constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditRecordsPage extends StatefulWidget {
  const EditRecordsPage({super.key});

  @override
  State<EditRecordsPage> createState() => _EditRecordsPageState();
}

class _EditRecordsPageState extends State<EditRecordsPage> {
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _showRunning = true; // true for running, false for closed

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    print('Fetching data...');
    setState(() => _isLoading = true);
    try {
      await _loadTransactions();
    } catch (e, st) {
      print('Error in _fetchData:');
      print(e);
      print(st);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadTransactions() async {
    print('Loading transactions...');
    try {
      final db = await DatabaseHelper.instance.database;
      print('Database opened.');
      final List<Map<String, dynamic>> result = await db.query(
        'transactions',
        where: 'status = ?',
        whereArgs: [_showRunning ? 1 : 0],
        orderBy: 'date DESC',
      );
      print('Query complete. Rows: \\${result.length}');

      String query = _searchController.text;
      final filtered = result.where((transaction) {
        final fullName =
            transaction['full_name']?.toString().toLowerCase() ?? '';
        final accountNumber = transaction['account_number']?.toString() ?? '';
        return fullName.contains(query.toLowerCase()) ||
            accountNumber.contains(query);
      }).toList();

      setState(() {
        _transactions = result;
        _filteredTransactions = filtered;
      });
    } catch (e, st) {
      print('Error in _loadTransactions:');
      print(e);
      print(st);
    }
  }

  void _filterSearchResults(String query) {
    final filtered = _transactions.where((transaction) {
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

  void _deleteTransaction(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction deleted successfully'),
        backgroundColor: Colors.green,
      ),
    );
    _fetchData(); // Refresh the list
  }

  String formatDate(String date) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
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

  Widget buildTransactionCard(Map<String, dynamic> data) {
    return Card(
      elevation: 6,
      shadowColor: primary_color.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
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
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.account_box, "Account No", "${data['account_number']}"),
                  _buildInfoRow(Icons.account_balance_wallet, "Balance", "₹${data['balance']}"),
                  _buildInfoRow(Icons.calendar_today, "Date", formatDate(data['date'])),
                ],
              ),
            ),
            // Action icons
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: primary_color, size: 24),
                  onPressed: () {
                    _showEditDialog(data);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade700, size: 24),
                  onPressed: () {
                    _deleteTransaction(data['id']);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> data) {
    TextEditingController nameController = TextEditingController(text: data['full_name']);
    TextEditingController accountController = TextEditingController(text: data['account_number'].toString());
    TextEditingController contactController = TextEditingController(text: data['contact_number'] ?? '');
    TextEditingController addressController = TextEditingController(text: data['address'] ?? '');
    TextEditingController guarantorController = TextEditingController(text: data['guarantor_name'] ?? '');
    TextEditingController loanAmountController = TextEditingController(text: data['loan_amount'].toString());
    TextEditingController interestController = TextEditingController(text: data['interest'].toString());
    TextEditingController cfBalanceController = TextEditingController(text: data['cf_balance'].toString());
    TextEditingController withdrawalController = TextEditingController(text: data['withdrawal_amount'].toString());
    TextEditingController creditController = TextEditingController(text: data['credit_amount'].toString());
    TextEditingController dateController = TextEditingController(text: data['date'] ?? '');

    double balance = data['balance'];
    int statusValue = data['status'];

    void recalculateBalance() {
      double interest = double.tryParse(interestController.text) ?? 0.0;
      double cfBalance = double.tryParse(cfBalanceController.text) ?? 0.0;
      double withdrawal = double.tryParse(withdrawalController.text) ?? 0.0;
      double credit = double.tryParse(creditController.text) ?? 0.0;

      balance = interest + cfBalance + withdrawal - credit;
    }

    recalculateBalance();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Transaction"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: accountController,
                    decoration: const InputDecoration(labelText: 'Account No'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: contactController, decoration: const InputDecoration(labelText: 'Contact No')),
                  const SizedBox(height: 8),
                  TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
                  const SizedBox(height: 8),
                  TextField(controller: guarantorController, decoration: const InputDecoration(labelText: 'Guarantor Name')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: loanAmountController,
                    decoration: const InputDecoration(labelText: 'Loan Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: interestController,
                    decoration: const InputDecoration(labelText: 'Interest'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() => recalculateBalance());
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cfBalanceController,
                    decoration: const InputDecoration(labelText: 'CF Balance'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() => recalculateBalance());
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: withdrawalController,
                    decoration: const InputDecoration(labelText: 'Withdrawal Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() => recalculateBalance());
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: creditController,
                    decoration: const InputDecoration(labelText: 'Credit Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() => recalculateBalance());
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Date'),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(dateController.text) ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData(
                              primaryColor: primary_color,
                              colorScheme: ColorScheme.light(primary: primary_color),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() {
                          dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: "₹${balance.toStringAsFixed(2)}"),
                    decoration: const InputDecoration(labelText: 'Balance'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: statusValue,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("Running")),
                      DropdownMenuItem(value: 0, child: Text("Closed")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          statusValue = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel", style: TextStyle(color: primary_color)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primary_color),
                child: const Text("Update", style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  final db = await DatabaseHelper.instance.database;
                  await db.update(
                    'transactions',
                    {
                      'full_name': nameController.text,
                      'account_number': int.tryParse(accountController.text),
                      'contact_number': contactController.text,
                      'address': addressController.text,
                      'guarantor_name': guarantorController.text,
                      'loan_amount': double.tryParse(loanAmountController.text) ?? 0.0,
                      'interest': double.tryParse(interestController.text) ?? 0.0,
                      'cf_balance': double.tryParse(cfBalanceController.text) ?? 0.0,
                      'withdrawal_amount': double.tryParse(withdrawalController.text) ?? 0.0,
                      'credit_amount': double.tryParse(creditController.text) ?? 0.0,
                      'balance': balance,
                      'date': dateController.text,
                      'status': statusValue,
                    },
                    where: 'id = ?',
                    whereArgs: [data['id']],
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Transaction updated")),
                  );
                  _fetchData();
                },
              )
            ],
          );
        });
      },
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

    // Format today's date as 'dd-MM-yyyy' to match DB format
    final today = DateFormat('d-M-yyyy').format(DateTime.now());

    final List<Map<String, dynamic>> result = await db.query(
      'transactions',
      where: "date = ?",
      whereArgs: [today],
      orderBy: 'date DESC',
    );

    setState(() {
      _filteredTransactions = result;
    });

    print("Filtered ${result.length} transactions for today ($today)");
  }



  Future<void> _filterYesterday() async {
    final db = await DatabaseHelper.instance.database;

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final formatted = DateFormat('d-M-yyyy').format(yesterday); // Match DB format

    final List<Map<String, dynamic>> result = await db.query(
      'transactions',
      where: "date = ?",
      whereArgs: [formatted],
      orderBy: 'date DESC',
    );

    setState(() {
      _filteredTransactions = result;
    });

  }


  void _filterThisMonth() {
    final now = DateTime.now();
    setState(() {
      _filteredTransactions = _transactions.where((tx) {
        final dateStr = tx['date'];
        DateTime? date;

        try {
          date = DateFormat('dd-MM-yyyy').parse(dateStr);
        } catch (e) {
          // If parsing fails, treat as invalid
          return false;
        }

        return date.year == now.year && date.month == now.month;
      }).toList();
    });
  }


  void _filterThisYear() {
    final now = DateTime.now();
    setState(() {
      _filteredTransactions = _transactions.where((tx) {
        final dateStr = tx['date'];
        DateTime? date;

        try {
          date = DateFormat('dd-MM-yyyy').parse(dateStr);
        } catch (e) {
          return false;
        }

        return date.year == now.year;
      }).toList();
    });
  }


  Future<void> _selectDate() async {
    final picked = await showDatePicker(
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

    if (picked != null) {
      final formatted = DateFormat('dd-MM-yyyy').format(picked);
      setState(() {
        _filteredTransactions = _transactions.where((tx) {
          final dateStr = tx['date'];
          DateTime? date;

          try {
            date = DateFormat('dd-MM-yyyy').parse(dateStr);
          } catch (e) {
            return false;
          }
          return date.year == picked.year && date.month == picked.month && date.day == picked.day;
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date to filter.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg_color,
      appBar: AppBar(
        title: const Text(
          'Edit Records',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primary_color,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            onSelected: (value) {
              switch (value) {
                case 'today':
                  _filterToday();
                  break;
                case 'yesterday':
                  _filterYesterday();
                  break;
                case 'select_date':
                  _selectDate();
                  break;
                case 'this_month':
                  _filterThisMonth();
                  break;
                case 'this_year':
                  _filterThisYear();
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
              _buildPopupItem("This Year", Icons.event, 'this_year'),
              _buildPopupItem("Till Now", Icons.history, 'till_now'),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: primary_color),
                ),
              ),
            if (!_isLoading) ...[
              // Search Bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
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
              // Radio buttons for filtering
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
                          setState(() => _showRunning = value);
                          _fetchData();
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
                          setState(() => _showRunning = value);
                          _fetchData();
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
                child: _filteredTransactions.isEmpty
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
                              "No records match the current filter.",
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
                        padding: const EdgeInsets.only(bottom: 20),
                        itemBuilder: (context, index) {
                          return buildTransactionCard(
                            _filteredTransactions[index],
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
