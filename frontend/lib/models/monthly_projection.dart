/// Monthly financial projection
class MonthlyProjection {
  final DateTime month;
  final double projectedIncome;
  final double projectedExpenses;
  final double projectedDebt;
  final double projectedDsr;
  final double projectedBalance;
  final String status; // HEALTHY, WARNING, CRITICAL

  MonthlyProjection({
    required this.month,
    required this.projectedIncome,
    required this.projectedExpenses,
    required this.projectedDebt,
    required this.projectedDsr,
    required this.projectedBalance,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'month': month.toIso8601String(),
      'projected_income': projectedIncome,
      'projected_expenses': projectedExpenses,
      'projected_debt': projectedDebt,
      'projected_dsr': projectedDsr,
      'projected_balance': projectedBalance,
      'status': status,
    };
  }
}

/// What-If scenario parameters
class WhatIfScenario {
  final String name;
  final double? incomeChange; // e.g., -500 for $500 decrease
  final double? expenseChange;
  final double? newDebtAmount;
  final String? newDebtType; // MONTHLY, BNPL, etc.

  WhatIfScenario({
    required this.name,
    this.incomeChange,
    this.expenseChange,
    this.newDebtAmount,
    this.newDebtType,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (incomeChange != null) 'income_change': incomeChange,
      if (expenseChange != null) 'expense_change': expenseChange,
      if (newDebtAmount != null) 'new_debt_amount': newDebtAmount,
      if (newDebtType != null) 'new_debt_type': newDebtType,
    };
  }
}

/// Complete projection result with baseline and scenarios
class ProjectionResult {
  final List<MonthlyProjection> baseline;
  final Map<String, List<MonthlyProjection>> scenarios;

  ProjectionResult({
    required this.baseline,
    this.scenarios = const {},
  });
}
