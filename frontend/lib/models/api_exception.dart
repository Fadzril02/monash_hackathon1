/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

/// Exception for safe balance errors
class SafeBalanceException extends ApiException {
  final double? safeBalance;
  final double? requestedAmount;

  SafeBalanceException({
    required String message,
    this.safeBalance,
    this.requestedAmount,
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);

  @override
  String toString() {
    if (safeBalance != null && requestedAmount != null) {
      return 'Safe Balance Error: $message\n'
          'Your safe balance: RM ${safeBalance!.toStringAsFixed(2)}\n'
          'Requested amount: RM ${requestedAmount!.toStringAsFixed(2)}';
    }
    return message;
  }
}
