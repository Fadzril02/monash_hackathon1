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
