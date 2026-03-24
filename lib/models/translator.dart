/// 翻译员卡片/详情 — 符合 api-contract.md 8.1
class Translator {
  final String id;
  final String name;
  final String avatar;
  final List<String> languagePairs;
  final List<String> serviceCities;
  final Map<String, dynamic> pricingRules;
  final double ratingSummary;
  final List<String> serviceTypes;
  final List<String> industries;
  final List<String> serviceVenues;
  final List<String> certificates;
  final String intro;
  final String expoExperience;
  final double? dailyRateAed;
  final String auditStatus;
  final bool isAvailable;
  final bool isFavorited;

  const Translator({
    required this.id,
    required this.name,
    this.avatar = '',
    this.languagePairs = const [],
    this.serviceCities = const [],
    this.pricingRules = const {},
    this.ratingSummary = 0.0,
    this.serviceTypes = const [],
    this.industries = const [],
    this.serviceVenues = const [],
    this.certificates = const [],
    this.intro = '',
    this.expoExperience = '',
    this.dailyRateAed,
    this.auditStatus = 'APPROVED',
    this.isAvailable = true,
    this.isFavorited = false,
  });

  String get languageLabel => languagePairs.join(' / ');
  String get cityLabel => serviceCities.join(' / ');

  double? get basePriceAed {
    if (dailyRateAed != null) return dailyRateAed;
    if (pricingRules.containsKey('daily')) {
      return (pricingRules['daily'] as num?)?.toDouble();
    }
    return null;
  }

  String get priceLabel {
    final p = basePriceAed;
    if (p == null) return '价格面议';
    return 'AED ${p.toInt()}/天';
  }

  factory Translator.fromJson(Map<String, dynamic> json) {
    return Translator(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['realName'] ?? '',
      avatar: json['avatar'] ?? '',
      languagePairs: List<String>.from(json['languagePairs'] ?? []),
      serviceCities: List<String>.from(json['serviceCities'] ?? []),
      pricingRules: Map<String, dynamic>.from(json['pricingRules'] ?? {}),
      ratingSummary: (json['ratingSummary'] ?? 0).toDouble(),
      serviceTypes: List<String>.from(json['serviceTypes'] ?? []),
      industries: List<String>.from(json['industries'] ?? []),
      serviceVenues: List<String>.from(json['serviceVenues'] ?? []),
      certificates: List<String>.from(json['certificates'] ?? []),
      intro: json['intro'] ?? '',
      expoExperience: json['expoExperience'] ?? '',
      dailyRateAed: json['dailyRateAed'] != null ? (json['dailyRateAed'] as num).toDouble() : null,
      auditStatus: json['auditStatus'] ?? 'APPROVED',
      isAvailable: json['isAvailable'] ?? true,
      isFavorited: json['isFavorited'] ?? false,
    );
  }
}
