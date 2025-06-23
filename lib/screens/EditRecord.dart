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
  String _currentFilter = 'all'; // values: 'all', 'today', 'yesterday', 'thisMonth', 'selectdate', 'tillnow'
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with edit & delete buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left content
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
                // Right action icons
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
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Center button
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary_color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                icon: const Icon(Icons.change_circle, color: Colors.white),
                label: const Text(
                  "Change Status",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                onPressed: () {
                  // You can handle status update logic here
                  _showStatusChangeDialog(data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusChangeDialog(Map<String, dynamic> data) {
    String currentStatus = data['status'] == 1 ? "Running" : "Closed";
    String newStatus = data['status'] == 1 ? "Closed" : "Running";
    int newStatusValue = data['status'] == 1 ? 0 : 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Change Status",
            style: TextStyle(fontWeight: FontWeight.bold, color: primary_color),
          ),
          content: Text(
            "Are you sure you want to change the status from $currentStatus to $newStatus?",
          ),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: primary_color)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary_color),
              child: const Text("Yes", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final db = await DatabaseHelper.instance.database;
                await db.update(
                  'transactions',
                  {'status': newStatusValue},
                  where: 'id = ?',
                  whereArgs: [data['id']],
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Status changed to $newStatus"),
                  ),
                );
                _fetchData(); // refresh list
              },
            ),
          ],
        );
      },
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
            title: const Text("Edit Transaction", style: TextStyle(color: primary_color, fontWeight: FontWeight.bold)),
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
              setState(() {}); // Force refresh
              switch (value) {
                case 'today':
                  _currentFilter = 'today';
                  _filterToday();
                  break;
                case 'yesterday':
                  _currentFilter = 'yesterday';
                  _filterYesterday();
                  break;
                case 'select_date':
                  _currentFilter = 'selectdate';
                  _selectedDate = null;
                  _onSelectDatePressed();
                  break;
                case 'thisMonth':
                  _currentFilter = 'thisMonth';
                  _filterThisMonth();
                  break;
                case 'tillnow':
                  _currentFilter = 'tillnow';
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
                'thisMonth',
              ),
              _buildPopupItem("Till Now", Icons.history, 'tillnow'),
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
