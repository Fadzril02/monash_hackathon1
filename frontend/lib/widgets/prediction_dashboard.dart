import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/monthly_projection.dart';
import '../services/projection_service.dart';

class PredictionDashboard extends StatelessWidget {
  const PredictionDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isProjectionLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (appState.financialAnalysis == null) {
          return const Center(
            child: Text('No financial data available'),
          );
        }

        final analysis = appState.financialAnalysis!;
        final projectionResult = appState.projectionResult;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current DSR Card
              _buildDsrCard(analysis.currentDsr),
              const SizedBox(height: 16),

              // Financial Summary
              _buildFinancialSummary(analysis),
              const SizedBox(height: 16),

              // Financial Health Indicators (Phase 1)
              _buildFinancialHealthIndicators(analysis, appState),
              const SizedBox(height: 16),

              // Advanced Metrics (Phase 2)
              _buildAdvancedMetrics(analysis, appState),
              const SizedBox(height: 16),

              // Financial Stress Index (Phase 3)
              _buildFinancialStressIndex(analysis, appState),
              const SizedBox(height: 16),

              // Smart Recommendations (Phase 3)
              _buildSmartRecommendations(analysis, appState),
              const SizedBox(height: 24),

              // DSR Projection Chart
              if (projectionResult != null) ...[
                const Text(
                  '12-Month DSR Projection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDsrChart(projectionResult),
                const SizedBox(height: 24),

                // Balance Projection Chart
                const Text(
                  'Balance Projection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildChartLegend(projectionResult),
                const SizedBox(height: 16),
                _buildBalanceChart(projectionResult),
                const SizedBox(height: 24),

                // Scenarios Summary
                if (projectionResult.scenarios.isNotEmpty) ...[
                  const Text(
                    'What-If Scenarios',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildScenariosList(context, projectionResult),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDsrCard(double currentDsr) {
    final status = ProjectionService.getDsrStatusDescription(currentDsr);
    final colorName = ProjectionService.getDsrColorName(currentDsr);
    final color = colorName == 'red'
        ? Colors.red
        : colorName == 'orange'
            ? Colors.orange
            : Colors.green;

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current DSR',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${currentDsr.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (currentDsr / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(analysis) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Avg Monthly Income',
              formatter.format(analysis.avgMonthlyIncome),
              Colors.green,
            ),
            _buildSummaryRow(
              'Avg Monthly Expenses',
              formatter.format(analysis.avgMonthlyExpenses),
              Colors.orange,
            ),
            _buildSummaryRow(
              'Total Debt Payments',
              formatter.format(analysis.totalDebtPayments),
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHealthIndicators(analysis, AppState appState) {
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final currentBalance = appState.safeBalance?.currentBalance ?? 0.0;

    // Calculate Phase 1 Indicators
    final avgIncome = analysis.avgMonthlyIncome;
    final avgExpenses = analysis.avgMonthlyExpenses;
    final totalDebt = analysis.totalDebtPayments;

    // 1. Net Cash Flow
    final netCashFlow = avgIncome - avgExpenses - totalDebt;
    final cashFlowColor = netCashFlow > 0 ? Colors.green : Colors.red;

    // 2. Savings Rate
    final savingsRate = avgIncome > 0
        ? ((avgIncome - avgExpenses - totalDebt) / avgIncome) * 100
        : 0.0;
    final savingsRateColor = savingsRate >= 20
        ? Colors.green
        : savingsRate >= 10
            ? Colors.orange
            : Colors.red;

    // 3. Emergency Fund Ratio
    final emergencyFundRatio = avgExpenses > 0
        ? currentBalance / avgExpenses
        : 0.0;
    final emergencyFundColor = emergencyFundRatio >= 6
        ? Colors.green
        : emergencyFundRatio >= 3
            ? Colors.orange
            : Colors.red;
    final emergencyFundStatus = emergencyFundRatio >= 6
        ? 'Excellent'
        : emergencyFundRatio >= 3
            ? 'Good'
            : 'At Risk';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Health Indicators',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Net Cash Flow
            _buildHealthIndicatorRow(
              icon: Icons.account_balance_wallet,
              label: 'Net Monthly Cash Flow',
              value: '${netCashFlow >= 0 ? '+' : ''}${formatter.format(netCashFlow)}',
              status: netCashFlow > 0 ? 'Surplus' : 'Deficit',
              color: cashFlowColor,
            ),
            const Divider(height: 20),

            // Savings Rate
            _buildHealthIndicatorRow(
              icon: Icons.savings,
              label: 'Savings Rate',
              value: '${savingsRate.toStringAsFixed(1)}%',
              status: savingsRate >= 20
                  ? 'Excellent (Target: 20%+)'
                  : 'Below Target (20%+)',
              color: savingsRateColor,
            ),
            const Divider(height: 20),

            // Emergency Fund
            _buildHealthIndicatorRow(
              icon: Icons.shield,
              label: 'Emergency Fund Coverage',
              value: '${emergencyFundRatio.toStringAsFixed(1)} months',
              status: '$emergencyFundStatus (Target: 3-6 months)',
              color: emergencyFundColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicatorRow({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedMetrics(analysis, AppState appState) {
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final currentBalance = appState.safeBalance?.currentBalance ?? 0.0;
    final avgExpenses = analysis.avgMonthlyExpenses;
    final avgIncome = analysis.avgMonthlyIncome;
    final totalDebt = analysis.totalDebtPayments;
    final subscriptions = appState.subscriptions;

    // 4. Spending Velocity
    final dailySpending = (avgExpenses + totalDebt) / 30;
    final financialRunway = dailySpending > 0
        ? currentBalance / dailySpending
        : 999.0;
    final runwayColor = financialRunway > 180
        ? Colors.green
        : financialRunway > 90
            ? Colors.orange
            : Colors.red;

    // 5. Subscription Burden
    final subscriptionTotal = subscriptions
        .where((s) => s.liabilityType == 'SUBSCRIPTION')
        .fold(0.0, (sum, s) => sum + s.amount);
    final subscriptionBurden = avgIncome > 0
        ? (subscriptionTotal / avgIncome) * 100
        : 0.0;
    final subscriptionColor = subscriptionBurden < 5
        ? Colors.green
        : subscriptionBurden < 10
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Spending Velocity Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed, color: runwayColor, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Spending Velocity',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Average',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatter.format(dailySpending),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: runwayColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${financialRunway.toStringAsFixed(0)} days',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: runwayColor,
                            ),
                          ),
                          Text(
                            'of runway',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (financialRunway / 365).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(runwayColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Subscription Burden Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.subscriptions, color: subscriptionColor, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Subscription Burden',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Total',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatter.format(subscriptionTotal),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: subscriptionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${subscriptionBurden.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: subscriptionColor,
                            ),
                          ),
                          Text(
                            'of income',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subscriptionBurden < 5
                      ? 'Healthy (Target: <5%)'
                      : 'Consider reducing subscriptions',
                  style: TextStyle(
                    fontSize: 12,
                    color: subscriptionColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Expense Breakdown Card
        _buildExpenseBreakdown(appState),
      ],
    );
  }

  Widget _buildExpenseBreakdown(AppState appState) {
    final subscriptions = appState.subscriptions;

    // Group by type
    final Map<String, double> breakdown = {};
    for (var sub in subscriptions) {
      breakdown[sub.liabilityType] = (breakdown[sub.liabilityType] ?? 0.0) + sub.amount;
    }

    final total = breakdown.values.fold(0.0, (sum, val) => sum + val);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Recurring Expenses Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...breakdown.entries.map((entry) {
              final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
              final color = _getCategoryColor(entry.key);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        Text(
                          'RM ${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'SUBSCRIPTION':
        return Colors.purple;
      case 'UTILITY':
        return Colors.orange;
      case 'INSURANCE':
        return Colors.blue;
      case 'LOAN':
        return Colors.red;
      case 'BNPL':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFinancialStressIndex(analysis, AppState appState) {
    final currentBalance = appState.safeBalance?.currentBalance ?? 0.0;
    final avgIncome = analysis.avgMonthlyIncome;
    final avgExpenses = analysis.avgMonthlyExpenses;
    final totalDebt = analysis.totalDebtPayments;
    final currentDsr = analysis.currentDsr;

    // Calculate individual scores (0-100)

    // 1. DSR Score (30% weight) - Lower is better
    final dsrScore = currentDsr < 20 ? 100.0
        : currentDsr < 30 ? 80.0
        : currentDsr < 40 ? 60.0
        : currentDsr < 50 ? 40.0
        : 20.0;

    // 2. Emergency Fund Score (25% weight) - More months is better
    final emergencyFundMonths = avgExpenses > 0 ? currentBalance / avgExpenses : 0.0;
    final emergencyScore = emergencyFundMonths >= 6 ? 100.0
        : emergencyFundMonths >= 3 ? 70.0
        : emergencyFundMonths >= 1 ? 40.0
        : 20.0;

    // 3. Savings Rate Score (20% weight) - Higher is better
    final netCashFlow = avgIncome - avgExpenses - totalDebt;
    final savingsRate = avgIncome > 0 ? (netCashFlow / avgIncome) * 100 : 0.0;
    final savingsScore = savingsRate >= 25 ? 100.0
        : savingsRate >= 20 ? 80.0
        : savingsRate >= 15 ? 60.0
        : savingsRate >= 10 ? 40.0
        : 20.0;

    // 4. Cash Flow Score (15% weight) - Positive is better
    final cashFlowScore = netCashFlow > 1000 ? 100.0
        : netCashFlow > 500 ? 80.0
        : netCashFlow > 0 ? 60.0
        : netCashFlow > -500 ? 40.0
        : 20.0;

    // 5. Runway Score (10% weight) - More days is better
    final dailySpending = (avgExpenses + totalDebt) / 30;
    final runway = dailySpending > 0 ? currentBalance / dailySpending : 999.0;
    final runwayScore = runway >= 180 ? 100.0
        : runway >= 90 ? 70.0
        : runway >= 30 ? 40.0
        : 20.0;

    // Calculate weighted total
    final stressIndex = (
      dsrScore * 0.30 +
      emergencyScore * 0.25 +
      savingsScore * 0.20 +
      cashFlowScore * 0.15 +
      runwayScore * 0.10
    );

    // Determine status
    final String status;
    final Color statusColor;
    if (stressIndex >= 80) {
      status = 'Excellent';
      statusColor = Colors.green;
    } else if (stressIndex >= 70) {
      status = 'Healthy';
      statusColor = Colors.lightGreen;
    } else if (stressIndex >= 50) {
      status = 'Moderate Stress';
      statusColor = Colors.orange;
    } else if (stressIndex >= 40) {
      status = 'High Stress';
      statusColor = Colors.deepOrange;
    } else {
      status = 'Critical';
      statusColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Stress Index',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  // Circular Progress Indicator
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: stressIndex / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${stressIndex.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                              Text(
                                'out of 100',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            // Score breakdown
            _buildScoreRow('DSR Management', dsrScore, 0.30),
            _buildScoreRow('Emergency Fund', emergencyScore, 0.25),
            _buildScoreRow('Savings Rate', savingsScore, 0.20),
            _buildScoreRow('Cash Flow', cashFlowScore, 0.15),
            _buildScoreRow('Financial Runway', runwayScore, 0.10),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, double score, double weight) {
    final color = score >= 80 ? Colors.green
        : score >= 60 ? Colors.lightGreen
        : score >= 40 ? Colors.orange
        : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${score.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              '(${(weight * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartRecommendations(analysis, AppState appState) {
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final currentBalance = appState.safeBalance?.currentBalance ?? 0.0;
    final avgIncome = analysis.avgMonthlyIncome;
    final avgExpenses = analysis.avgMonthlyExpenses;
    final totalDebt = analysis.totalDebtPayments;
    final currentDsr = analysis.currentDsr;
    final subscriptions = appState.subscriptions;

    // Calculate metrics for recommendations
    final emergencyFundMonths = avgExpenses > 0 ? currentBalance / avgExpenses : 0.0;
    final netCashFlow = avgIncome - avgExpenses - totalDebt;
    final savingsRate = avgIncome > 0 ? (netCashFlow / avgIncome) * 100 : 0.0;
    final dailySpending = (avgExpenses + totalDebt) / 30;
    final runway = dailySpending > 0 ? currentBalance / dailySpending : 999.0;
    final subscriptionTotal = subscriptions
        .where((s) => s.liabilityType == 'SUBSCRIPTION')
        .fold(0.0, (sum, s) => sum + s.amount);
    final subscriptionBurden = avgIncome > 0 ? (subscriptionTotal / avgIncome) * 100 : 0.0;

    // Generate recommendations (prioritized)
    final List<Map<String, dynamic>> recommendations = [];

    // Critical priority
    if (runway < 30) {
      final neededReduction = ((currentBalance / 30) - dailySpending).abs();
      recommendations.add({
        'priority': 'critical',
        'icon': Icons.warning_amber_rounded,
        'title': 'Critical: Low Financial Runway',
        'description': 'Only ${runway.toStringAsFixed(0)} days of runway remaining',
        'action': 'Reduce spending by ${formatter.format(neededReduction)}/day',
        'impact': 'Extend runway to 30+ days',
      });
    }

    if (emergencyFundMonths < 1) {
      final targetAmount = avgExpenses * 3;
      final monthsNeeded = netCashFlow > 0 ? (targetAmount - currentBalance) / netCashFlow : 0;
      recommendations.add({
        'priority': 'critical',
        'icon': Icons.shield_outlined,
        'title': 'Build Emergency Fund ASAP',
        'description': 'You have less than 1 month of emergency savings',
        'action': 'Save ${formatter.format(targetAmount - currentBalance)} to reach 3 months',
        'impact': monthsNeeded > 0 ? 'Target: ${monthsNeeded.toStringAsFixed(0)} months' : 'Start now',
      });
    } else if (emergencyFundMonths < 3) {
      final targetAmount = avgExpenses * 3;
      recommendations.add({
        'priority': 'important',
        'icon': Icons.shield_outlined,
        'title': 'Grow Emergency Fund',
        'description': 'Current: ${emergencyFundMonths.toStringAsFixed(1)} months (Target: 3-6)',
        'action': 'Save ${formatter.format(targetAmount - currentBalance)} more',
        'impact': 'Reach minimum 3-month safety net',
      });
    }

    // Important priority
    if (currentDsr >= 40) {
      recommendations.add({
        'priority': 'important',
        'icon': Icons.trending_down,
        'title': 'High DSR - Reduce Debt',
        'description': 'Current DSR: ${currentDsr.toStringAsFixed(1)}% (Target: <40%)',
        'action': 'Consider debt consolidation or extra payments',
        'impact': 'Lower monthly debt burden',
      });
    }

    if (savingsRate < 20 && savingsRate > 0) {
      final targetSavings = avgIncome * 0.20;
      final additionalNeeded = targetSavings - netCashFlow;
      recommendations.add({
        'priority': 'important',
        'icon': Icons.savings_outlined,
        'title': 'Increase Savings Rate',
        'description': 'Current: ${savingsRate.toStringAsFixed(1)}% (Target: 20%+)',
        'action': 'Save extra ${formatter.format(additionalNeeded)}/month',
        'impact': 'Build wealth faster',
      });
    }

    // Suggested priority
    if (subscriptionBurden > 5) {
      recommendations.add({
        'priority': 'suggested',
        'icon': Icons.subscriptions_outlined,
        'title': 'Review Subscriptions',
        'description': 'Subscriptions: ${subscriptionBurden.toStringAsFixed(1)}% of income',
        'action': 'Cancel unused services to save ${formatter.format(subscriptionTotal * 0.3)}',
        'impact': 'Reduce monthly burden',
      });
    }

    // Positive feedback
    if (recommendations.isEmpty) {
      recommendations.add({
        'priority': 'positive',
        'icon': Icons.celebration,
        'title': 'Great Financial Health!',
        'description': 'Your finances are in excellent shape',
        'action': 'Keep up the good work',
        'impact': 'Stay disciplined!',
      });
    } else if (emergencyFundMonths >= 6 && savingsRate >= 20) {
      recommendations.add({
        'priority': 'positive',
        'icon': Icons.thumb_up,
        'title': 'Strong Emergency Fund',
        'description': '${emergencyFundMonths.toStringAsFixed(1)} months coverage',
        'action': 'Excellent! Consider investing surplus',
        'impact': 'Build long-term wealth',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Smart Recommendations',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...recommendations.take(3).map((rec) => _buildRecommendationCard(rec)),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final priority = rec['priority'] as String;

    final Color bgColor;
    final Color iconColor;
    final String priorityLabel;

    switch (priority) {
      case 'critical':
        bgColor = Colors.red.shade50;
        iconColor = Colors.red;
        priorityLabel = '🚨 CRITICAL PRIORITY';
        break;
      case 'important':
        bgColor = Colors.orange.shade50;
        iconColor = Colors.orange;
        priorityLabel = '⚠️ IMPORTANT';
        break;
      case 'suggested':
        bgColor = Colors.blue.shade50;
        iconColor = Colors.blue;
        priorityLabel = '💡 SUGGESTED';
        break;
      case 'positive':
        bgColor = Colors.green.shade50;
        iconColor = Colors.green;
        priorityLabel = '✅ DOING GREAT';
        break;
      default:
        bgColor = Colors.grey.shade50;
        iconColor = Colors.grey;
        priorityLabel = 'INFO';
    }

    return Card(
      color: bgColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(rec['icon'], color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        priorityLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rec['title'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rec['description'],
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: iconColor),
                      const SizedBox(width: 6),
                      const Text(
                        'Action:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rec['action'],
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.trending_up, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Impact: ${rec['impact']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDsrChart(ProjectionResult projectionResult) {
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}%',
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 3,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < projectionResult.baseline.length) {
                    final month = projectionResult.baseline[index].month;
                    return Text(
                      DateFormat('MMM').format(month),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            // Baseline
            LineChartBarData(
              spots: projectionResult.baseline.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value.projectedDsr,
                );
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
            // Warning threshold
            LineChartBarData(
              spots: List.generate(
                projectionResult.baseline.length,
                (index) => FlSpot(
                  index.toDouble(),
                  ProjectionService.dsrWarningThreshold,
                ),
              ),
              isCurved: false,
              color: Colors.red.withOpacity(0.5),
              barWidth: 2,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
          ],
          minY: 0,
          maxY: 100,
        ),
      ),
    );
  }

  Widget _buildChartLegend(ProjectionResult projectionResult) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        // Current Scenario (Green solid line)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 3,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            const Text(
              'Current Scenario',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        // What-If Scenarios (Dashed lines)
        if (projectionResult.scenarios.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 3,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.red,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: CustomPaint(
                  painter: DashedLinePainter(color: Colors.red),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'What-If Scenarios',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBalanceChart(ProjectionResult projectionResult) {
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text('\$${(value / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 3,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < projectionResult.baseline.length) {
                    final month = projectionResult.baseline[index].month;
                    return Text(
                      DateFormat('MMM').format(month),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            // Baseline
            LineChartBarData(
              spots: projectionResult.baseline.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value.projectedBalance,
                );
              }).toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
            // Scenarios
            ...projectionResult.scenarios.entries.map((scenario) {
              return LineChartBarData(
                spots: scenario.value.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.projectedBalance,
                  );
                }).toList(),
                isCurved: true,
                color: Colors.primaries[
                    projectionResult.scenarios.keys.toList().indexOf(scenario.key) %
                        Colors.primaries.length],
                barWidth: 2,
                dashArray: [5, 5],
                dotData: const FlDotData(show: false),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildScenariosList(
      BuildContext context, ProjectionResult projectionResult) {
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: projectionResult.scenarios.length,
        itemBuilder: (context, index) {
          final scenarioName = projectionResult.scenarios.keys.elementAt(index);
          final scenario = projectionResult.scenarios[scenarioName]!;
          final finalProjection = scenario.last;

          return ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.primaries[index % Colors.primaries.length],
                shape: BoxShape.circle,
              ),
            ),
            title: Text(scenarioName),
            subtitle: Text(
              'Final DSR: ${finalProjection.projectedDsr.toStringAsFixed(1)}% | '
              'Balance: \$${finalProjection.projectedBalance.toStringAsFixed(2)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                Provider.of<AppState>(context, listen: false)
                    .removeWhatIfScenario(scenarioName);
              },
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for dashed line in legend
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 4;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
