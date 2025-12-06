/// Promotion Model
/// Represents a promotional offer from the backend API
class Promotion {
  final int promotionId;
  final String title;
  final String? subtitle;
  final String description;
  final String? imageUrl;
  final PromotionType promotionType;
  final String? conditions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Promotion({
    required this.promotionId,
    required this.title,
    this.subtitle,
    required this.description,
    this.imageUrl,
    required this.promotionType,
    this.conditions,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Promotion from JSON
  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      promotionId: json['promotion_id'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      promotionType: PromotionType.fromString(json['promotion_type'] as String),
      conditions: json['conditions'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Promotion to JSON
  Map<String, dynamic> toJson() {
    return {
      'promotion_id': promotionId,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'image_url': imageUrl,
      'promotion_type': promotionType.value,
      'conditions': conditions,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Promotion Type Enum
enum PromotionType {
  bnpl('bnpl'),
  cashback('cashback'),
  voucher('voucher'),
  premiumPerk('premium_perk');

  final String value;
  const PromotionType(this.value);

  static PromotionType fromString(String value) {
    switch (value) {
      case 'bnpl':
        return PromotionType.bnpl;
      case 'cashback':
        return PromotionType.cashback;
      case 'voucher':
        return PromotionType.voucher;
      case 'premium_perk':
        return PromotionType.premiumPerk;
      default:
        return PromotionType.cashback;
    }
  }

  String get displayName {
    switch (this) {
      case PromotionType.bnpl:
        return 'Buy Now Pay Later';
      case PromotionType.cashback:
        return 'Cashback';
      case PromotionType.voucher:
        return 'Voucher';
      case PromotionType.premiumPerk:
        return 'Premium Perk';
    }
  }
}


