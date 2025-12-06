class SafeBalance {
  final String userExternalId;
  final double currentBalance;
  final double upcomingLiabilities;
  final double safeBalance;
  final String status; // HEALTHY, WARNING, CRITICAL
  final int upcomingCount;
  final DateTime? nextPaymentDate;
  final double? nextPaymentAmount;
  final int lookaheadDays;
  final DateTime timestamp;

  SafeBalance({
    required this.userExternalId,
    required this.currentBalance,
    required this.upcomingLiabilities,
    required this.safeBalance,
    required this.status,
    required this.upcomingCount,
    this.nextPaymentDate,
    this.nextPaymentAmount,
    required this.lookaheadDays,
    required this.timestamp,
  });

  factory SafeBalance.fromJson(Map<String, dynamic> json) {
    return SafeBalance(
      userExternalId: json['user_external_id'] as String,
      currentBalance: double.parse(json['current_balance'].toString()),
      upcomingLiabilities: double.parse(json['upcoming_liabilities'].toString()),
      safeBalance: double.parse(json['safe_balance'].toString()),
      status: json['status'] as String,
      upcomingCount: json['upcoming_count'] as int,
      nextPaymentDate: json['next_payment_date'] != null
          ? DateTime.parse(json['next_payment_date'] as String)
          : null,
      nextPaymentAmount: json['next_payment_amount'] != null
          ? double.parse(json['next_payment_amount'].toString())
          : null,
      lookaheadDays: json['lookahead_days'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_external_id': userExternalId,
      'current_balance': currentBalance,
      'upcoming_liabilities': upcomingLiabilities,
      'safe_balance': safeBalance,
      'status': status,
      'upcoming_count': upcomingCount,
      'next_payment_date': nextPaymentDate?.toIso8601String(),
      'next_payment_amount': nextPaymentAmount,
      'lookahead_days': lookaheadDays,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Get status color
  int get statusColorValue {
    switch (status) {
      case 'HEALTHY':
        return 0xFF10B981; // Green
      case 'WARNING':
        return 0xFFF59E0B; // Amber
      case 'CRITICAL':
        return 0xFFEF4444; // Red
      default:
        return 0xFF64748B; // Gray
    }
  }

  bool get isHealthy => status == 'HEALTHY';
  bool get isWarning => status == 'WARNING';
  bool get isCritical => status == 'CRITICAL';
}
