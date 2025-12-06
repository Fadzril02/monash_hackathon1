import '../models/financial_analysis.dart';
import '../models/monthly_projection.dart';
import '../models/subscription.dart';

/// Service for calculating financial projections
class ProjectionService {
  /// DSR thresholds
  static const double dsrHealthyThreshold = 30.0;
  static const double dsrWarningThreshold = 40.0;

  /// Calculate 12-month baseline projection
  List<MonthlyProjection> calculateBaselineProjection({
    required FinancialAnalysis analysis,
    required List<Subscription> subscriptions,
    required double currentBalance,
  }) {
    final projections = <MonthlyProjection>[];
    var runningBalance = currentBalance;

    for (var i = 0; i < 12; i++) {
      final month = DateTime.now().add(Duration(days: 30 * i));

      // Use historical averages for income and expenses
      final projectedIncome = analysis.avgMonthlyIncome;
      final projectedExpenses = analysis.avgMonthlyExpenses;
      final projectedDebt = analysis.totalDebtPayments;

      // Calculate DSR
      final projectedDsr =
          projectedIncome > 0 ? (projectedDebt / projectedIncome) * 100 : 0.0;

      // Calculate projected balance
      runningBalance =
          runningBalance + projectedIncome - projectedExpenses - projectedDebt;

      // Determine status
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
