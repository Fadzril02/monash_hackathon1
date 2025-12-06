import '../models/financial_analysis.dart';
import '../models/monthly_projection.dart';
import '../models/subscription.dart';

/// Service for calculating financial projections
class ProjectionService {
  /// DSR thresholds
  static const double dsrHealthyThreshold = 30.0;
  static const double dsrWarningThreshold = 40.0;

  /// Calculate 12-month baseline projection with realistic variations
  List<MonthlyProjection> calculateBaselineProjection({
    required FinancialAnalysis analysis,
    required List<Subscription> subscriptions,
    required double currentBalance,
  }) {
    final projections = <MonthlyProjection>[];
    var runningBalance = currentBalance;

    // Calculate net cash flow to determine trajectory
    final baseNetCashFlow = analysis.avgMonthlyIncome -
                            analysis.avgMonthlyExpenses -
                            analysis.totalDebtPayments;
    final isDeficit = baseNetCashFlow < 0;

    for (var i = 0; i < 12; i++) {
      final month = DateTime.now().add(Duration(days: 30 * i));
      final monthIndex = month.month;

      // 1. INCOME VARIATIONS (±5% realistic fluctuation)
      // Simulate irregular freelance income, bonuses, etc.
      var projectedIncome = analysis.avgMonthlyIncome;

      // Add income variation based on month
      if (monthIndex == 12) {
        // December: Bonus month (+20%)
        projectedIncome = projectedIncome * 1.20;
      } else if (i % 3 == 0 && i > 0) {
        // Every 3 months: Freelance income (+10%)
        projectedIncome = projectedIncome * 1.10;
      } else if (i % 4 == 2) {
        // Some months: Lower income (-5%)
        projectedIncome = projectedIncome * 0.95;
      }

      // 2. EXPENSE VARIATIONS (seasonal + inflation)
      var projectedExpenses = analysis.avgMonthlyExpenses;

      // Monthly inflation (0.3% = 3.6% annual)
      projectedExpenses = projectedExpenses * (1 + (i * 0.003));

      // Seasonal variations
      if (monthIndex == 12) {
        // December: Holiday spending (+25%)
        projectedExpenses = projectedExpenses * 1.25;
      } else if (monthIndex == 1 || monthIndex == 2) {
        // Jan-Feb: CNY, back-to-school (+15%)
        projectedExpenses = projectedExpenses * 1.15;
      } else if (monthIndex == 6 || monthIndex == 7) {
        // Mid-year sales (+10%)
        projectedExpenses = projectedExpenses * 1.10;
      }

      // 3. DEBT PAYMENTS (may increase if struggling)
      var projectedDebt = analysis.totalDebtPayments;

      // If balance is critically low, debt burden feels heavier
      if (runningBalance < 1000 && runningBalance > 0) {
        // Simulate potential late fees or higher interest
        projectedDebt = projectedDebt * 1.05;
      } else if (runningBalance <= 0) {
        // Critical: Can't pay full debt, DSR spikes
        projectedDebt = projectedDebt * 1.10; // Penalties
      }

      // 4. CALCULATE DSR (changes based on income variations)
      final projectedDsr =
          projectedIncome > 0 ? (projectedDebt / projectedIncome) * 100 : 0.0;

      // 5. CALCULATE PROJECTED BALANCE
      runningBalance =
          runningBalance + projectedIncome - projectedExpenses - projectedDebt;

      // 6. DETERMINE STATUS
      final status = _calculateStatus(projectedDsr.toDouble(), runningBalance.toDouble());

      projections.add(MonthlyProjection(
        month: month,
        projectedIncome: projectedIncome,
        projectedExpenses: projectedExpenses,
        projectedDebt: projectedDebt,
        projectedDsr: projectedDsr,
        projectedBalance: runningBalance,
        status: status,
      ));
    }

    return projections;
  }

  /// Calculate What-If scenario projection
  List<MonthlyProjection> calculateWhatIfProjection({
    required FinancialAnalysis analysis,
    required List<Subscription> subscriptions,
    required double currentBalance,
    required WhatIfScenario scenario,
  }) {
    final projections = <MonthlyProjection>[];
    var runningBalance = currentBalance;

    // Apply scenario adjustments
    final adjustedIncome = analysis.avgMonthlyIncome + (scenario.incomeChange ?? 0);
    final adjustedExpenses = analysis.avgMonthlyExpenses + (scenario.expenseChange ?? 0);
    final adjustedDebt = analysis.totalDebtPayments + (scenario.newDebtAmount ?? 0);

    for (var i = 0; i < 12; i++) {
      final month = DateTime.now().add(Duration(days: 30 * i));

      // Calculate DSR with scenario adjustments
      final projectedDsr =
          adjustedIncome > 0 ? (adjustedDebt / adjustedIncome) * 100 : 0.0;

      // Calculate projected balance
      runningBalance =
          runningBalance + adjustedIncome - adjustedExpenses - adjustedDebt;

      // Determine status
      final status = _calculateStatus(projectedDsr.toDouble(), runningBalance.toDouble());

      projections.add(MonthlyProjection(
        month: month,
        projectedIncome: adjustedIncome,
        projectedExpenses: adjustedExpenses,
        projectedDebt: adjustedDebt,
        projectedDsr: projectedDsr,
        projectedBalance: runningBalance,
        status: status,
      ));
    }

    return projections;
  }

  /// Calculate complete projection with baseline and scenarios
  ProjectionResult calculateProjections({
    required FinancialAnalysis analysis,
    required List<Subscription> subscriptions,
    required double currentBalance,
    List<WhatIfScenario>? scenarios,
  }) {
    // Calculate baseline
    final baseline = calculateBaselineProjection(
      analysis: analysis,
      subscriptions: subscriptions,
      currentBalance: currentBalance,
    );

    // Calculate scenarios if provided
    final scenarioProjections = <String, List<MonthlyProjection>>{};
    if (scenarios != null) {
      for (final scenario in scenarios) {
        scenarioProjections[scenario.name] = calculateWhatIfProjection(
          analysis: analysis,
          subscriptions: subscriptions,
          currentBalance: currentBalance,
          scenario: scenario,
        );
      }
    }

    return ProjectionResult(
      baseline: baseline,
      scenarios: scenarioProjections,
    );
  }

  /// Determine status based on DSR and balance
  String _calculateStatus(double dsr, double balance) {
    if (dsr >= dsrWarningThreshold || balance < 0) {
      return 'CRITICAL';
    } else if (dsr >= dsrHealthyThreshold || balance < 500) {
      return 'WARNING';
    } else {
      return 'HEALTHY';
    }
  }

  /// Get DSR status description
  static String getDsrStatusDescription(double dsr) {
    if (dsr >= dsrWarningThreshold) {
      return 'CRITICAL: High debt burden';
    } else if (dsr >= dsrHealthyThreshold) {
      return 'WARNING: Elevated debt levels';
    } else {
      return 'HEALTHY: Manageable debt';
    }
  }

  /// Get DSR color based on status
  static String getDsrColorName(double dsr) {
    if (dsr >= dsrWarningThreshold) {
      return 'red';
    } else if (dsr >= dsrHealthyThreshold) {
      return 'orange';
    } else {
      return 'green';
    }
  }
}
