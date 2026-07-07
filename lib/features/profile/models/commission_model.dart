class CommissionModel {
  final String id;
  final double totalEarnings;
  final double availableBalance;
  final double pendingBalance;
  final List<CommissionTransaction> transactions;

  CommissionModel({
    required this.id,
    required this.totalEarnings,
    required this.availableBalance,
    required this.pendingBalance,
    required this.transactions,
  });

  factory CommissionModel.fromJson(Map<String, dynamic> json) {
    final transactionsList = json['transactions'] as List? ?? [];
    return CommissionModel(
      id: json['id']?.toString() ?? '',
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (json['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      transactions: transactionsList
          .map((t) => CommissionTransaction.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalEarnings': totalEarnings,
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }
}

class CommissionTransaction {
  final String id;
  final String orderId;
  final double amount;
  final String status;
  final DateTime createdAt;

  CommissionTransaction({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory CommissionTransaction.fromJson(Map<String, dynamic> json) {
    return CommissionTransaction(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
