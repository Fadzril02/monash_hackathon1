class Subscription {
  final String liabilityId; // Changed from int to String (UUID)
  final String liabilityType;
  final String liabilityName;
  final double amount;
  final String recurrencePattern;
  final DateTime nextDueDate;
  final DateTime? lastPaidDate;
  final bool isVerified;
  final DateTime createdAt;

  Subscription({
    required this.liabilityId,
    required this.liabilityType,
    required this.liabilityName,
    required this.amount,
    required this.recurrencePattern,
    required this.nextDueDate,
    this.lastPaidDate,
    required this.isVerified,
    required this.createdAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    try {
      return Subscription(
        liabilityId: json['liability_id'].toString(), // Convert to String to handle both int and UUID
        liabilityType: json['liability_type'] as String,
        liabilityName: json['liability_name'] as String,
        amount: double.parse(json['amount'].toString()),
        recurrencePattern: json['recurrence_pattern'] as String,
        nextDueDate: json['next_due_date'] is String
            ? DateTime.parse(json['next_due_date'] as String)
            : DateTime.now().add(const Duration(days: 30)),
        lastPaidDate: json['last_paid_date'] != null && json['last_paid_date'] is String
            ? DateTime.parse(json['last_paid_date'] as String)
            : null,
        isVerified: json['is_verified'] == true,
        createdAt: json['created_at'] is String
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing subscription: $e');
      print('JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'liability_id': liabilityId,
      'liability_type': liabilityType,
      'liability_name': liabilityName,
      'amount': amount,
      'recurrence_pattern': recurrencePattern,
      'next_due_date': nextDueDate.toIso8601String(),
      'last_paid_date': lastPaidDate?.toIso8601String(),
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get emoji icon based on liability type
  String get icon {
    switch (liabilityType) {
      case 'SUBSCRIPTION':
        if (liabilityName.contains('Netflix')) return '🎬';
        if (liabilityName.contains('Spotify')) return '🎵';
        if (liabilityName.contains('YouTube')) return '📺';
        return '📱';
      case 'UTILITY':
        if (liabilityName.contains('Electricity') || liabilityName.contains('TNB'))
          return '⚡';
        if (liabilityName.contains('Internet') || liabilityName.contains('Unifi'))
          return '📡';
        if (liabilityName.contains('Phone')) return '📱';
        return '🏠';
      case 'LOAN':
        if (liabilityName.contains('Car')) return '🚗';
        if (liabilityName.contains('Home')) return '🏠';
        return '💳';
      case 'BNPL':
        return '💰';
      case 'INSURANCE':
        return '🛡️';
      default:
        return '📄';
    }
  }

  /// Get tag color based on liability type
  int get tagColorValue {
    switch (liabilityType) {
      case 'SUBSCRIPTION':
        return 0xFFA855F7; // Purple
      case 'UTILITY':
        return 0xFF22C55E; // Green
      case 'LOAN':
        return 0xFF3B82F6; // Blue
      case 'BNPL':
        return 0xFFF59E0B; // Amber
      case 'INSURANCE':
        return 0xFF8B5CF6; // Violet
      default:
        return 0xFF64748B; // Gray
    }
  }
}
