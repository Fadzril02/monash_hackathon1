import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/monthly_projection.dart';

class WhatIfDialog extends StatefulWidget {
  const WhatIfDialog({Key? key}) : super(key: key);

  @override
  State<WhatIfDialog> createState() => _WhatIfDialogState();
}

class _WhatIfDialogState extends State<WhatIfDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _incomeChangeController = TextEditingController();
  final _expenseChangeController = TextEditingController();
  final _newDebtController = TextEditingController();

  String _selectedDebtType = 'MONTHLY';
  final List<String> _debtTypes = ['MONTHLY', 'BNPL', 'LOAN', 'MORTGAGE'];

  @override
  void dispose() {
    _nameController.dispose();
    _incomeChangeController.dispose();
    _expenseChangeController.dispose();
    _newDebtController.dispose();
    super.dispose();
  }

  void _submitScenario() {
    if (_formKey.currentState!.validate()) {
      final scenario = WhatIfScenario(
        name: _nameController.text.trim(),
        incomeChange: _incomeChangeController.text.isEmpty
            ? null
            : double.parse(_incomeChangeController.text),
        expenseChange: _expenseChangeController.text.isEmpty
            ? null
            : double.parse(_expenseChangeController.text),
        newDebtAmount: _newDebtController.text.isEmpty
            ? null
            : double.parse(_newDebtController.text),
        newDebtType: _newDebtController.text.isEmpty ? null : _selectedDebtType,
      );

      Provider.of<AppState>(context, listen: false).addWhatIfScenario(scenario);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create What-If Scenario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter changes to simulate their impact on your finances over 12 months.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Scenario Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Scenario Name *',
                  hintText: 'e.g., "New Job", "Extra Loan"',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a scenario name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Income Change
              const Text(
                'Income Change',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _incomeChangeController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Income Change',
                  hintText: 'e.g., 500 or -200',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                  helperText: 'Positive for increase, negative for decrease',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final parsed = double.tryParse(value);
                    if (parsed == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Expense Change
              const Text(
                'Expense Change',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _expenseChangeController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Expense Change',
                  hintText: 'e.g., 100 or -50',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                  helperText: 'Positive for increase, negative for decrease',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final parsed = double.tryParse(value);
                    if (parsed == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // New Debt
              const Text(
                'New Debt',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _newDebtController,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Payment',
                        hintText: 'e.g., 150',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final parsed = double.tryParse(value);
                          if (parsed == null || parsed < 0) {
                            return 'Please enter a valid positive number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDebtType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _debtTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDebtType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Leave all fields empty except name to keep current values',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitScenario,
          child: const Text('Create Scenario'),
        ),
      ],
    );
  }
}
