/// Financial analysis data from backend
class FinancialAnalysis {
  final double avgMonthlyIncome;
  final double avgMonthlyExpenses;
  final double totalDebtPayments;
  final double currentDsr;
  final String dsrStatus;
  final DateTime calculatedAt;

  FinancialAnalysis({
    required this.avgMonthlyIncome,
    required this.avgMonthlyExpenses,
    required this.totalDebtPayments,
    required this.currentDsr,
    required this.dsrStatus,
    required this.calculatedAt,
  });

  factory FinancialAnalysis.fromJson(Map<String, dynamic> json) {
    return FinancialAnalysis(
      avgMonthlyIncome: double.parse(json['avg_monthly_income'].toString()),
      avgMonthlyExpenses: double.parse(json['avg_monthly_expenses'].toString()),
      totalDebtPayments: double.parse(json['total_debt_payments'].toString()),
      currentDsr: double.parse(json['current_dsr'].toString()),
      dsrStatus: json['dsr_status'] as String,
      calculatedAt: DateTime.parse(json['calculated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avg_monthly_income': avgMonthlyIncome,
      'avg_monthly_expenses': avgMonthlyExpenses,
      'total_debt_payments': totalDebtPayments,
      'current_dsr': currentDsr,
      'dsr_status': dsrStatus,
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }
}
