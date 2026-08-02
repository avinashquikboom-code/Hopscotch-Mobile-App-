enum WalletTransactionType { credit, debit }

enum WalletTransactionCategory { topup, purchase, refund, cashback, admin }

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? 0);
  return 0;
}

class WalletTransaction {
  final String id;
  final double amount;
  final WalletTransactionType type;
  final WalletTransactionCategory category;
  final String description;
  final DateTime createdAt;
  final String status;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.createdAt,
    this.status = 'completed',
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      type: json['type'] == 'debit' ? WalletTransactionType.debit : WalletTransactionType.credit,
      category: _parseCategory(json['category']),
      description: json['description']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status']?.toString() ?? 'completed',
    );
  }

  static WalletTransactionCategory _parseCategory(dynamic cat) {
    switch (cat?.toString().toLowerCase()) {
      case 'topup':
        return WalletTransactionCategory.topup;
      case 'purchase':
        return WalletTransactionCategory.purchase;
      case 'refund':
        return WalletTransactionCategory.refund;
      case 'cashback':
        return WalletTransactionCategory.cashback;
      case 'admin':
        return WalletTransactionCategory.admin;
      default:
        return WalletTransactionCategory.topup;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type == WalletTransactionType.debit ? 'debit' : 'credit',
      'category': category.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}

enum RewardType {
  purchase,
  referral,
  campaign,
  review,
  redeemed,
  expired,
  reversed,
}

class RewardHistoryItem {
  final String id;
  final int points;
  final RewardType type;
  final String description;
  final DateTime createdAt;
  final DateTime? expiresAt;

  RewardHistoryItem({
    required this.id,
    required this.points,
    required this.type,
    required this.description,
    required this.createdAt,
    this.expiresAt,
  });

  factory RewardHistoryItem.fromJson(Map<String, dynamic> json) {
    return RewardHistoryItem(
      id: json['id']?.toString() ?? '',
      points: _parseInt(json['points']),
      type: _parseRewardType(json['type']),
      description: json['description']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
    );
  }

  static RewardType _parseRewardType(dynamic type) {
    switch (type?.toString().toLowerCase()) {
      case 'purchase':
        return RewardType.purchase;
      case 'referral':
        return RewardType.referral;
      case 'campaign':
        return RewardType.campaign;
      case 'review':
        return RewardType.review;
      case 'redeemed':
        return RewardType.redeemed;
      case 'expired':
        return RewardType.expired;
      case 'reversed':
        return RewardType.reversed;
      default:
        return RewardType.purchase;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points,
      'type': type.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

class ReferralData {
  final String referralCode;
  final double referralEarnings;
  final int friendsJoined;
  final int successfulReferrals;
  final int pendingRewards;

  ReferralData({
    this.referralCode = '',
    this.referralEarnings = 0.0,
    this.friendsJoined = 0,
    this.successfulReferrals = 0,
    this.pendingRewards = 0,
  });

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    return ReferralData(
      referralCode: json['referralCode']?.toString() ?? '',
      referralEarnings: _parseDouble(json['referralEarnings']),
      friendsJoined: _parseInt(json['friendsJoined']),
      successfulReferrals: _parseInt(json['successfulReferrals']),
      pendingRewards: _parseInt(json['pendingRewards']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referralCode': referralCode,
      'referralEarnings': referralEarnings,
      'friendsJoined': friendsJoined,
      'successfulReferrals': successfulReferrals,
      'pendingRewards': pendingRewards,
    };
  }
}

class CashbackItem {
  final String id;
  final double amount;
  final String status; // 'credited', 'pending', 'expired'
  final String description;
  final DateTime createdAt;
  final DateTime? expiresAt;

  CashbackItem({
    required this.id,
    required this.amount,
    required this.status,
    required this.description,
    required this.createdAt,
    this.expiresAt,
  });

  factory CashbackItem.fromJson(Map<String, dynamic> json) {
    return CashbackItem(
      id: json['id']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      status: json['status']?.toString() ?? 'credited',
      description: json['description']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'status': status,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

class GiftCardItem {
  final String id;
  final String code;
  final double amount;
  final double balance;
  final String status; // 'active', 'redeemed', 'expired'
  final DateTime createdAt;
  final DateTime? expiresAt;

  GiftCardItem({
    required this.id,
    required this.code,
    required this.amount,
    required this.balance,
    required this.status,
    required this.createdAt,
    this.expiresAt,
  });

  factory GiftCardItem.fromJson(Map<String, dynamic> json) {
    return GiftCardItem(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      balance: _parseDouble(json['balance']),
      status: json['status']?.toString() ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'amount': amount,
      'balance': balance,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}
