import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _bookIdController = TextEditingController();
  final TextEditingController _loanPeriodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial values (replace with your backend values)
    _customerIdController.text = '6';
    _bookIdController.text = '6';
    _loanPeriodController.text = '14';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildIdSettingsCard(),
              const SizedBox(height: 20),
              _buildLoanPeriodCard(),
              const SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Card _buildIdSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ID Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildNumberInputField(
              controller: _customerIdController,
              label: 'Customer ID Digits',
              hint: 'Number of digits in customer IDs',
              min: 3,
              max: 10,
            ),
            const SizedBox(height: 15),
            _buildNumberInputField(
              controller: _bookIdController,
              label: 'Book ID Digits',
              hint: 'Number of digits in book ISBNs',
              min: 3,
              max: 13,
            ),
          ],
        ),
      ),
    );
  }

  Card _buildLoanPeriodCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loan Period',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildNumberInputField(
              controller: _loanPeriodController,
              label: 'Loan Duration',
              hint: 'Maximum loan period in days',
              min: 1,
              max: 365,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int min,
    required int max,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.numbers),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        final numValue = int.tryParse(value);
        if (numValue == null) {
          return 'Please enter a valid number';
        }
        if (numValue < min || numValue > max) {
          return 'Must be between $min and $max';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.save),
      label: const Text('Save Settings'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          // Save logic (connect to your backend)
          _showConfirmationDialog();
        }
      },
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings Saved'),
        content: const Text('New configurations have been saved successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _bookIdController.dispose();
    _loanPeriodController.dispose();
    super.dispose();
  }
}