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
  List<Map<String, dynamic>> transactions = [];
  String searchText = '';
  bool showRunning = true;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> result = await db.query(
      'transactions',
      where: 'status = ?',
      whereArgs: [showRunning ? 1 : 0],
      orderBy: 'date DESC',
    );

    setState(() {
      transactions = result;
    });
  }

  void _deleteTransaction(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    fetchTransactions();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted')),
    );
  }

  String formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredTransactions = transactions.where((transaction) {
      return transaction['full_name']
          .toString()
          .toLowerCase()
          .contains(searchText.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Records',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primary_color,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.blueGrey[900],
      body: SizedBox.expand(
        child: Column(
          children: [
            // Sticky Search and Radio Buttons
            Container(
              color: bg_color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      hintStyle: const TextStyle(color: Colors.black),
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      filled: true,
                      fillColor: bg_color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: showRunning,
                        onChanged: (value) {
                          setState(() {
                            showRunning = value!;
                            fetchTransactions();
                          });
                        },
                        activeColor: primary_color,
                      ),
                      const Text('Running', style: TextStyle(color: Colors.black)),
                      const SizedBox(width: 20),
                      Radio<bool>(
                        value: false,
                        groupValue: showRunning,
                        onChanged: (value) {
                          setState(() {
                            showRunning = value!;
                            fetchTransactions();
                          });
                        },
                        activeColor: primary_color,
                      ),
                      const Text('Closed', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ],
              ),
            ),

            // Transaction List / No Records View
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 90,
                      color: Colors.blueGrey[400],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Transactions Found',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adding a new transaction.',
                      style: TextStyle(
                        color: Colors.blueGrey[300],
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  var record = filteredTransactions[index];
                  String dateText = formatDate(record['date']);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[800],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Leading icon/avatar
                          CircleAvatar(
                            backgroundColor: primary_color,
                            child: Text(
                              record['full_name'][0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Transaction Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record['full_name'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Acc No: ${record['account_number']}',
                                  style: TextStyle(
                                      color: Colors.blueGrey[300], fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${record['balance']} • $dateText',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          // More menu
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'Delete') {
                                _deleteTransaction(record['id']);
                              } else if (value == 'Edit') {
                                // Optional: handle edit
                              }
                            },
                            icon: const Icon(Icons.more_vert, color: Colors.white70),
                            color: Colors.blueGrey[900],
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'Edit',
                                child: Text('Edit', style: TextStyle(color: Colors.white)),
                              ),
                              const PopupMenuItem(
                                value: 'Delete',
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
