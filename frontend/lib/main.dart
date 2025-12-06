import 'package:flutter/material.dart';

void main() {
  runApp(const RytGuardApp());
}

class RytGuardApp extends StatelessWidget {
  const RytGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Light grey-blue bg
        useMaterial3: true,
      ),
      home: const RytGuardHomePage(),
    );
  }
}

class RytGuardHomePage extends StatelessWidget {
  const RytGuardHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // We use SingleChildScrollView to make the whole page scrollable
    // as per your single-page requirement.
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _HeaderSection(),
            const SizedBox(height: 20),

            // Main Content Padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SafeBalanceCard(),
                  const SizedBox(height: 20),
                  const _ChatbotWidget(),
                  const SizedBox(height: 20),

                  // Upcoming Bills Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upcoming Bills',
                        style: TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontSize: 16,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight
                              .w700, // Made slightly bolder for header
                        ),
                      ),
                      const Text(
                        '10 bills • Total: RM 1,648.50', // Updated total based on sum
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // List of Bills
                  const _BillItem(
                    icon: '🎬',
                    title: 'Netflix Premium',
                    subtitle: 'Today',
                    amount: 'RM 55.00',
                    tag: 'SUBSCRIPTION',
                    tagColor: Color(0xFFA855F7),
                  ),
                  const _BillItem(
                    icon: '⚡',
                    title: 'Electricity Bill',
                    subtitle: 'Dec 7',
                    amount: 'RM 185.00',
                    tag: 'UTILITY',
                    tagColor: Color(0xFF22C55E),
                  ),
                  const _BillItem(
                    icon: '🎵',
                    title: 'Spotify Family',
                    subtitle: 'Tomorrow',
                    amount: 'RM 28.90',
                    tag: 'SUBSCRIPTION',
                    tagColor: Color(0xFFA855F7),
                  ),
                  const _BillItem(
                    icon: '🚗',
                    title: 'Car Loan Payment',
                    subtitle: 'Dec 10',
                    amount: 'RM 850.00',
                    tag: 'LOAN',
                    tagColor: Color(0xFF3B82F6),
                  ),
                  const _BillItem(
                    icon: '📡',
                    title: 'Internet Bill',
                    subtitle: 'Dec 12',
                    amount: 'RM 129.00',
                    tag: 'UTILITY',
                    tagColor: Color(0xFF22C55E),
                  ),
                  const _BillItem(
                    icon: '📺',
                    title: 'YouTube Premium',
                    subtitle: 'Dec 15',
                    amount: 'RM 17.90',
                    tag: 'SUBSCRIPTION',
                    tagColor: Color(0xFFA855F7),
                  ),
                  const _BillItem(
                    icon: '📱',
                    title: 'Phone Bill',
                    subtitle: 'Dec 18',
                    amount: 'RM 98.00',
                    tag: 'UTILITY',
                    tagColor: Color(0xFF22C55E),
                  ),
                  const _BillItem(
                    icon: '🏠',
                    title: 'Home Loan',
                    subtitle: 'Dec 20',
                    amount: 'RM 1,200.00',
                    tag: 'LOAN',
                    tagColor: Color(0xFF3B82F6),
                  ),
                  const _BillItem(
                    icon: '🛡️',
                    title: 'Insurance Premium',
                    subtitle: 'Dec 25',
                    amount: 'RM 39.70',
                    tag: 'SUBSCRIPTION',
                    tagColor: Color(0xFFA855F7),
                  ),
                  const SizedBox(height: 40), // Bottom padding for scrolling
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 1. HEADER SECTION ---
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120, // Increased slightly to handle status bar
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 40,
      ), // Top padding for safe area
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
                children: [
                  const Text(
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

// --- 2. SAFE BALANCE CARD ---
class _SafeBalanceCard extends StatelessWidget {
  const _SafeBalanceCard();

  @override
  Widget build(BuildContext context) {
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
                // Header Row
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
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'HEALTHY',
                        style: TextStyle(
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

                // Math Rows
                const _BalanceRow(
                  label: 'Current Balance',
                  value: 'RM 7,623.00',
                  valueColor: Color(0xFF64748B),
                ),
                const SizedBox(height: 8),
                const _BalanceRow(
                  label: '- Upcoming Bills',
                  value: 'RM 1,648.50',
                  valueColor: Color(0xFFEF4444),
                ),
                const SizedBox(height: 20),

                // Big Safe Number
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
                    const Text(
                      'RM 5,974.50',
                      style: TextStyle(
                        color: Color(0xFF10B981),
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

          // Next Payment Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              color: const Color(0xFFF1F5F9),
            ),
            child: const Text(
              'Next payment: RM 55.00 on 5 Dec 2025',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontFamily: 'Arial',
              ),
            ),
          ),

          // Action Buttons
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
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _ActionButton(
                        text: 'Withdraw',
                        color: const Color(0xFF0000E6),
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
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _ActionButton(
                        text: 'Cancel Subscription',
                        color: const Color(0xFFEF4444),
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

  const _ActionButton({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

// --- 3. CHATBOT WIDGET ---
class _ChatbotWidget extends StatelessWidget {
  const _ChatbotWidget();

  @override
  Widget build(BuildContext context) {
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
          // Green Header
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
                        'Ask me about your finances',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chat Body
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Bubble
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0000E6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'How long can I last?',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // AI Bubble
                Align(
                  alignment: Alignment.centerLeft,
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
                          child: const Text(
                            'If you don\'t reload any money, you can last approximately 29 days before your safe balance runs out.',
                            style: TextStyle(
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
              ],
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
                // Pill Suggestions
                const SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SuggestionPill(text: 'Safe Balance?'),
                      SizedBox(width: 8),
                      _SuggestionPill(text: 'Can I afford RM 400?'),
                      SizedBox(width: 8),
                      _SuggestionPill(text: 'My bills?'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Input Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ask about your finances...',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
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
  }
}

class _SuggestionPill extends StatelessWidget {
  final String text;
  const _SuggestionPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      ),
    );
  }
}

// --- 4. BILL ITEM ROW ---
class _BillItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle; // Date
  final String amount;
  final String tag;
  final Color tagColor;

  const _BillItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.tag,
    required this.tagColor,
  });

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
          // Icon Box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          // Title & Tag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
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
                        color: tagColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
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
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            amount,
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
