import 'package:eFinance/db/database_helper.dart';
import 'package:eFinance/utils/Constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  final _accountNumberController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _interestController = TextEditingController();
  final _cfBalanceController = TextEditingController();
  final _withdrawalAmountController = TextEditingController();
  final _creditAmountController = TextEditingController();
  final _balanceController = TextEditingController();
  final _guarantorNameController = TextEditingController();
  final _dateController = TextEditingController();

  final FocusNode _accountFocusNode = FocusNode();


  @override
  void dispose() {
    _accountFocusNode.dispose();
    _interestController.removeListener(_updateBalance);
    _cfBalanceController.removeListener(_updateBalance);
    _withdrawalAmountController.removeListener(_updateBalance);
    _creditAmountController.removeListener(_updateBalance);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _dateController.text = "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}";

    _accountFocusNode.addListener(() async {
      if (!_accountFocusNode.hasFocus) {
        // Field lost focus, check account number
        final accNo = _accountNumberController.text.trim();
        if (accNo.isNotEmpty) {
          final exists = await DatabaseHelper.instance.isAccountNumberUsed(accNo);
          if (exists) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Duplicate Account"),
                content: const Text("Account number already exists."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // close dialog
                      _accountNumberController.clear(); // clear the field
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
          _interestController.addListener(_updateBalance);
          _cfBalanceController.addListener(_updateBalance);
          _withdrawalAmountController.addListener(_updateBalance);
          _creditAmountController.addListener(_updateBalance);
        }
      }
    });
  }
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primary_color, // calendar header color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}-${picked.month}-${picked.year}";
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      floatingLabelStyle: const TextStyle(
        color: primary_color,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: primary_color),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primary_color, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primary_color, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }


  void _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      final accountNumber = _accountNumberController.text.trim();
      final fullName = _fullNameController.text.trim();
      final contact = _contactNumberController.text.trim();
      final loanAmount = _loanAmountController.text.trim();
      final interest = _interestController.text.trim();
      final cfBalance = _cfBalanceController.text.trim();
      final withdrawalAmount = _withdrawalAmountController.text.trim();
      final creditAmount = _creditAmountController.text.trim();
      final balance = _balanceController.text.trim();
      final guarantorName = _guarantorNameController.text.trim();

      final loanVal = double.tryParse(loanAmount) ?? 0;
      final interestVal = double.tryParse(interest) ?? 0;
      final cfBalanceVal = double.tryParse(cfBalance) ?? 0;
      final withdrawalAmountVal = double.tryParse(withdrawalAmount) ?? 0;
      final creditAmountVal = double.tryParse(creditAmount) ?? 0;
      final balanceVal = double.tryParse(balance) ?? 0;


      final nameRegex = RegExp(r"^[a-zA-Z\s]+$");
      if (!nameRegex.hasMatch(fullName.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Name should have only alphabets and spaces")),
        );
        return;
      }

      if(accountNumber.length < 9 || accountNumber.length > 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter valid account number")),
        );
        return;
      }
      if(contact.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter valid 10 digit contact number")),
        );
        return;
      }

      if (loanVal < 0 || interestVal < 0 ||
          cfBalanceVal < 0 ||
          withdrawalAmountVal < 0 ||
          creditAmountVal < 0 ||
          balanceVal < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Amounts cannot be negative")),
        );
        return;
      }

      if (!nameRegex.hasMatch(guarantorName.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Guarantor name should have only alphabets and spaces")),
        );
        return;
      }
      final prefs = await SharedPreferences.getInstance();

      final transaction = {
        'email' : prefs.getString('user_email') ?? '',
        'account_number': accountNumber,
        'full_name': fullName,
        'contact_number': contact,
        'address': _addressController.text.trim(),
        'loan_amount': loanVal,
        'interest': interestVal,
        'cf_balance': cfBalanceVal,
        'withdrawal_amount': withdrawalAmountVal,
        'credit_amount': creditAmountVal,
        'balance': balanceVal,
        'guarantor_name': _guarantorNameController.text.trim(),
        'date': _dateController.text.trim(),
      };

      int result = await DatabaseHelper.instance.insertTransaction(transaction);

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction added successfully!")),
        );

        // Optional: Clear fields
        _fullNameController.clear();
        _accountNumberController.clear();
        _contactNumberController.clear();
        _addressController.clear();
        _loanAmountController.clear();
        _interestController.clear();
        _cfBalanceController.clear();
        _withdrawalAmountController.clear();
        _creditAmountController.clear();
        _balanceController.clear();
        _guarantorNameController.clear();

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to register user")),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaction Submitted")),
      );
    }
  }
  void _updateBalance() {
    final interest = double.tryParse(_interestController.text.trim()) ?? 0;
    final cfBalance = double.tryParse(_cfBalanceController.text.trim()) ?? 0;
    final withdrawal = double.tryParse(_withdrawalAmountController.text.trim()) ?? 0;
    final credit = double.tryParse(_creditAmountController.text.trim()) ?? 0;

    final calculatedBalance = interest + cfBalance + withdrawal - credit;
    _balanceController.text = calculatedBalance.toStringAsFixed(2); // update the balance
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg_color,
      appBar: AppBar(
        backgroundColor: primary_color,
        title: const Text("Add Transaction", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              TextFormField(
                controller: _accountNumberController,
                focusNode: _accountFocusNode, // <-- important
                decoration: _inputDecoration("Enter Account Number", Icons.account_box),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 15),
              TextFormField(controller: _fullNameController, decoration: _inputDecoration("Enter Full Name", Icons.person)),
              const SizedBox(height: 15),
              TextFormField(controller: _contactNumberController, decoration: _inputDecoration("Enter Contact Number", Icons.phone_in_talk_rounded), keyboardType: TextInputType.phone, maxLength: 10),
              const SizedBox(height: 15),
              TextFormField(controller: _addressController, decoration: _inputDecoration("Enter Address", Icons.add_location)),
              const SizedBox(height: 15),
              TextFormField(controller: _loanAmountController, decoration: _inputDecoration("Enter Loan Amount", Icons.money), keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              TextFormField(controller: _interestController, decoration: _inputDecoration("Enter Interest", Icons.percent), keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              TextFormField(controller: _cfBalanceController, decoration: _inputDecoration("C/F Balance", Icons.currency_rupee), keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              TextFormField(controller: _withdrawalAmountController, decoration: _inputDecoration("Enter Withdrawal Amount", Icons.arrow_circle_up), keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              TextFormField(controller: _creditAmountController, decoration: _inputDecoration("Enter Credit Amount", Icons.arrow_circle_down), keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              TextFormField(controller: _balanceController, decoration: _inputDecoration("Enter Balance", Icons.account_balance_wallet), keyboardType: TextInputType.number, readOnly: true),
              const SizedBox(height: 15),
              TextFormField(controller: _guarantorNameController, decoration: _inputDecoration("Enter Guarantor Name", Icons.supervisor_account)),
              const SizedBox(height: 15),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: _inputDecoration("Select Date", Icons.calendar_today),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary_color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Submit",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
