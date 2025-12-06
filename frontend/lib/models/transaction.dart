class Transaction {
  final String id;
  final double amount;
  final String type; // CREDIT or DEBIT
  final String? recipientName;
  final String? description;
  final DateTime date;
  final double previousBalance;
  final double newBalance;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    this.recipientName,
    this.description,
    required this.date,
    required this.previousBalance,
    required this.newBalance,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: double.parse(json['amount'].toString()),
      type: json['type'] as String,
      recipientName: json['recipientName'] as String?,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      previousBalance: double.parse(json['previousBalance'].toString()),
      newBalance: double.parse(json['newBalance'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'recipientName': recipientName,
      'description': description,
      'date': date.toIso8601String(),
      'previousBalance': previousBalance,
      'newBalance': newBalance,
    };
  }

  bool get isCredit => type == 'CREDIT';
  bool get isDebit => type == 'DEBIT';
}
