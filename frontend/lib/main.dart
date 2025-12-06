import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'providers/app_state.dart';
import 'models/subscription.dart';
import 'models/chat_message.dart';
import 'widgets/prediction_dashboard.dart';
import 'widgets/what_if_dialog.dart';
import 'widgets/promotions_page.dart';
import 'services/api_service.dart';
import 'models/promotion.dart';
import 'config/api_config.dart';

void main() {
  runApp(const RytGuardApp());
}

class RytGuardApp extends StatelessWidget {
  const RytGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          useMaterial3: true,
          fontFamily: 'Arial', // Set default font family
          fontFamilyFallback: const ['Roboto', 'sans-serif'], // Fallback fonts
        ),
        home: const RytGuardHomePage(),
      ),
    );
  }
}

class RytGuardHomePage extends StatefulWidget {
  const RytGuardHomePage({super.key});

  @override
  State<RytGuardHomePage> createState() => _RytGuardHomePageState();
}

class _RytGuardHomePageState extends State<RytGuardHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading && appState.safeBalance == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!appState.isBackendConnected) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Cannot connect to backend server',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Please make sure the server is running on port 3001'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => appState.initialize(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              // Main Dashboard
              SingleChildScrollView(
                child: Column(
                  children: [
                    const _HeaderSection(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PromotionBanner(),
                          const SizedBox(height: 20),
                          const _SafeBalanceCard(),
                          const SizedBox(height: 20),
                          const _ChatbotWidget(),
                          const SizedBox(height: 20),
                          _UpcomingBillsSection(subscriptions: appState.subscriptions),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Prediction Dashboard
              Column(
                children: [
                  const _HeaderSection(),
                  Expanded(
                    child: const PredictionDashboard(),
                  ),
                ],
              ),
              // Promotions Page
              const PromotionsPage(),
            ],
          ),
          floatingActionButton: _selectedIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const WhatIfDialog(),
                    );
                  },
                  icon: const Icon(Icons.science),
                  label: const Text('What-If'),
                  backgroundColor: const Color(0xFF0000E6),
                )
              : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            selectedItemColor: const Color(0xFF0000E6),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.trending_up),
                label: 'Predictions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_offer),
                label: 'Promotions',
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- HEADER SECTION ---
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
      color: const Color(0xFF0000E6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RytGuard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Arial',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Opacity(
                opacity: 0.9,
                child: const Text(
                  'Smart Banking Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Arial',
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'John Doe',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Arial',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'JD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Arial',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- SAFE BALANCE CARD ---
class _SafeBalanceCard extends StatelessWidget {
  const _SafeBalanceCard();

  String _formatCurrency(double amount) {
    return 'RM ${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final safeBalance = appState.safeBalance;

        if (safeBalance == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Safe Balance',
                          style: TextStyle(
                            color: Color(0xFF0A0A0A),
                            fontSize: 16,
                            fontFamily: 'Arial',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(safeBalance.statusColorValue),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            safeBalance.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'Arial',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _BalanceRow(
                      label: 'Current Balance',
                      value: _formatCurrency(safeBalance.currentBalance),
                      valueColor: const Color(0xFF64748B),
                    ),
                    const SizedBox(height: 8),
                    _BalanceRow(
                      label: '- Upcoming Bills',
                      value: _formatCurrency(safeBalance.upcomingLiabilities),
                      valueColor: const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Safe to Spend',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 16,
                            fontFamily: 'Arial',
                          ),
                        ),
                        Text(
                          _formatCurrency(safeBalance.safeBalance),
                          style: TextStyle(
                            color: Color(safeBalance.statusColorValue),
                            fontSize: 32,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (safeBalance.nextPaymentDate != null &&
                  safeBalance.nextPaymentAmount != null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    color: const Color(0xFFF1F5F9),
                  ),
                  child: Text(
                    'Next payment: ${_formatCurrency(safeBalance.nextPaymentAmount!)} on ${_formatDate(safeBalance.nextPaymentDate!)}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontFamily: 'Arial',
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            text: 'Reload Money',
                            color: const Color(0xFF10B981),
                            onTap: () => _showReloadDialog(context),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _ActionButton(
                            text: 'Withdraw',
                            color: const Color(0xFF0000E6),
                            onTap: () => _showWithdrawDialog(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            text: 'Add Subscription',
                            color: const Color(0xFFA855F7),
                            onTap: () => _showAddSubscriptionDialog(context),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _ActionButton(
                            text: 'Cancel Subscription',
                            color: const Color(0xFFEF4444),
                            onTap: () => _showCancelSubscriptionDialog(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReloadDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reload Money'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (RM)',
                  hintText: 'e.g., 1000',
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g., Bank transfer',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final amount = double.tryParse(amountController.text);
            if (amount == null || amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid amount')),
              );
              return;
            }

            Navigator.pop(context);

            final appState = Provider.of<AppState>(context, listen: false);
            final success = await appState.reloadMoney(
                amount,
                description: descriptionController.text.isEmpty
                    ? null
                    : descriptionController.text,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Money reloaded successfully!'
                        : appState.errorMessage ?? 'Failed to reload money'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reload'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    final amountController = TextEditingController();
    final recipientController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Money'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (RM)',
                  hintText: 'e.g., 500',
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: recipientController,
              decoration: const InputDecoration(
                labelText: 'Recipient Name',
                hintText: 'e.g., Ali Ahmad',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g., Payment for services',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final amount = double.tryParse(amountController.text);
            if (amount == null || amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid amount')),
              );
              return;
            }

            if (recipientController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter recipient name')),
              );
              return;
            }

            Navigator.pop(context);

            // Check withdrawal first
            final appState = Provider.of<AppState>(context, listen: false);
              try {
                final checkResult = await appState.checkWithdrawal(amount);
                final exceedsSafeBalance = checkResult['exceedsSafeBalance'] == true;
                final safeBalance = checkResult['safeBalance'];
                final canAfford = checkResult['canAfford'] == true;

                if (!canAfford) {
                  // Insufficient balance
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Insufficient balance'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                if (exceedsSafeBalance) {
                  // Show warning confirmation dialog
                  if (context.mounted) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Warning',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This withdrawal (RM ${amount.toStringAsFixed(2)}) exceeds your safe balance (RM ${safeBalance.toStringAsFixed(2)}).',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'This means you may not have enough to cover your upcoming bills and expenses.',
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Do you want to proceed anyway?',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Proceed'),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) {
                      return; // User cancelled
                    }
                  }
                }

                // Proceed with withdrawal
                final success = await appState.withdrawMoney(
                  amount,
                  recipientController.text,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Money withdrawn successfully!'
                          : appState.errorMessage ?? 'Failed to withdraw money'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error checking withdrawal: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedType = 'SUBSCRIPTION';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Subscription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Name',
                    hintText: 'e.g., Spotify Premium',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (RM)',
                    hintText: 'e.g., 19.90',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'SUBSCRIPTION', child: Text('Subscription')),
                    DropdownMenuItem(value: 'UTILITY', child: Text('Utility')),
                    DropdownMenuItem(value: 'LOAN', child: Text('Loan')),
                    DropdownMenuItem(value: 'BNPL', child: Text('BNPL')),
                    DropdownMenuItem(
                        value: 'INSURANCE', child: Text('Insurance')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Next Due Date'),
                  subtitle: Text(DateFormat('d MMM yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter subscription name')),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                Navigator.pop(context);

                final appState = Provider.of<AppState>(context, listen: false);
                final success = await appState.addSubscription(
                  name: nameController.text,
                  amount: amount,
                  type: selectedType,
                  nextDueDate: selectedDate,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Subscription added successfully!'
                          : appState.errorMessage ?? 'Failed to add subscription'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelSubscriptionDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final subscriptions = appState.subscriptions;

    if (subscriptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active subscriptions to cancel')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final subscription = subscriptions[index];
              return ListTile(
                leading: Text(subscription.icon, style: const TextStyle(fontSize: 24)),
                title: Text(subscription.liabilityName),
                subtitle: Text('RM ${subscription.amount.toStringAsFixed(2)}'),
                onTap: () async {
                  Navigator.pop(context);

                  final success =
                      await appState.cancelSubscription(subscription.liabilityId);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Subscription cancelled successfully!'
                            : appState.errorMessage ??
                                'Failed to cancel subscription'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _BalanceRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// --- CHATBOT WIDGET ---
class _ChatbotWidget extends StatefulWidget {
  const _ChatbotWidget();

  @override
  State<_ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<_ChatbotWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    final appState = Provider.of<AppState>(context, listen: false);
    appState.sendChatMessage(message);
    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final chatHistory = appState.chatHistory;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('🤖', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RytGuard Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Opacity(
                          opacity: 0.9,
                          child: const Text(
                            'Powered by Claude AI',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Action Buttons
              if (chatHistory.isEmpty)
                Container(
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickActionChip(
                            label: 'Check my financial health',
                            icon: '💰',
                            onTap: () => _sendMessage('What is my current financial health? Show me my DSR and upcoming bills.'),
                          ),
                          _QuickActionChip(
                            label: 'Can I afford this?',
                            icon: '🛒',
                            onTap: () => _sendMessage('Can I afford a purchase of RM 500?'),
                          ),
                          _QuickActionChip(
                            label: '12-month prediction',
                            icon: '📊',
                            onTap: () => _sendMessage('Show me my 12-month financial projection. What will my DSR look like?'),
                          ),
                          _QuickActionChip(
                            label: 'Spending tips',
                            icon: '💡',
                            onTap: () => _sendMessage('Give me tips to improve my financial health and reduce debt.'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Chat Body
              Container(
                color: const Color(0xFFF8FAFC),
                height: chatHistory.isEmpty ? 200 : 300,
                padding: const EdgeInsets.all(16),
                child: chatHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'Start a conversation with your AI assistant!',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: chatHistory.length +
                            (appState.isChatLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatHistory.length) {
                            // Loading indicator
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.fromBorderSide(
                                          BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text('🤖',
                                          style: TextStyle(fontSize: 16)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final message = chatHistory[index];
                          return _ChatBubble(message: message);
                        },
                      ),
              ),

              // Input Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Suggestion Pills
                    if (chatHistory.isEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _SuggestionPill(
                              text: 'Safe Balance?',
                              onTap: () => _sendMessage('What is my safe balance?'),
                            ),
                            const SizedBox(width: 8),
                            _SuggestionPill(
                              text: 'Can I afford RM 400?',
                              onTap: () => _sendMessage('Can I afford RM 400?'),
                            ),
                            const SizedBox(width: 8),
                            _SuggestionPill(
                              text: 'My bills?',
                              onTap: () => _sendMessage('What are my upcoming bills?'),
                            ),
                          ],
                        ),
                      ),
                    if (chatHistory.isEmpty) const SizedBox(height: 12),

                    // Input Field
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Ask about your finances...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                              onSubmitted: _sendMessage,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF10B981)),
                            onPressed: () => _sendMessage(_messageController.text),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: isUser
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF0000E6),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7),
                child: Text(
                  message.content,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🤖', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        message.content,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SuggestionPill extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionPill({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      ),
    );
  }
}

// --- UPCOMING BILLS SECTION ---
class _UpcomingBillsSection extends StatelessWidget {
  final List<Subscription> subscriptions;

  const _UpcomingBillsSection({required this.subscriptions});

  @override
  Widget build(BuildContext context) {
    final totalAmount =
        subscriptions.fold(0.0, (sum, sub) => sum + sub.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Bills',
              style: TextStyle(
                color: Color(0xFF0A0A0A),
                fontSize: 16,
                fontFamily: 'Arial',
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${subscriptions.length} bills • Total: RM ${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontFamily: 'Arial',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (subscriptions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No upcoming bills',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          )
        else
          ...subscriptions.map((subscription) => _BillItem(
                subscription: subscription,
              )),
      ],
    );
  }
}

class _BillItem extends StatelessWidget {
  final Subscription subscription;

  const _BillItem({required this.subscription});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final billDate = DateTime(date.year, date.month, date.day);

    if (billDate == today) {
      return 'Today';
    } else if (billDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(subscription.tagColorValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(subscription.icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      subscription.liabilityName,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(subscription.tagColorValue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subscription.liabilityType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(subscription.nextDueDate),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'RM ${subscription.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Action Chip Widget
class _QuickActionChip extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PROMOTION BANNER ---
class _PromotionBanner extends StatefulWidget {
  const _PromotionBanner();

  @override
  State<_PromotionBanner> createState() => _PromotionBannerState();
}

class _PromotionBannerState extends State<_PromotionBanner> {
  final ApiService _apiService = ApiService();
  final String _userExternalId = ApiConfig.defaultUserExternalId;
  Promotion? _topPromotion;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopPromotion();
  }

  Future<void> _loadTopPromotion() async {
    try {
      final promotions = await _apiService.getPromotions(
        userExternalId: _userExternalId,
      );

      if (promotions.isNotEmpty) {
        setState(() {
          _topPromotion = promotions[0]; // First promotion is the top-ranked one
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading top promotion: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _topPromotion == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Navigate to PromotionsPage by changing the selected index
        final homePageState = context.findAncestorStateOfType<_RytGuardHomePageState>();
        if (homePageState != null) {
          homePageState.setState(() {
            homePageState._selectedIndex = 2; // Promotions tab index
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6B35), // Bright orange-red
              const Color(0xFFFF8C42), // Lighter orange
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_offer,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Special Offer',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _topPromotion!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_topPromotion!.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _topPromotion!.subtitle!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Arrow icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
