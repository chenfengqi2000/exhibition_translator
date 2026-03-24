import '../models/translator.dart';
import 'api_client.dart';

class TranslatorService {
  final ApiClient _client;

  TranslatorService(this._client);

  /// 翻译员列表 — GET /marketplace/translators
  Future<TranslatorListResult> getTranslators({
    String? city,
    String? languagePair,
    String? translationType,
    String? industry,
    String? expoExperience,
    double? budgetMin,
    double? budgetMax,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (city != null && city.isNotEmpty) params['city'] = city;
    if (languagePair != null && languagePair.isNotEmpty) params['languagePair'] = languagePair;
    if (translationType != null && translationType.isNotEmpty) params['translationType'] = translationType;
    if (industry != null && industry.isNotEmpty) params['industry'] = industry;
    if (expoExperience != null && expoExperience.isNotEmpty) params['expoExperience'] = expoExperience;
    if (budgetMin != null) params['budgetMin'] = budgetMin;
    if (budgetMax != null) params['budgetMax'] = budgetMax;

    final data = await _client.get('/marketplace/translators', queryParameters: params);
    final list = (data['list'] as List)
        .map((e) => Translator.fromJson(e))
        .toList();
    return TranslatorListResult(list: list, total: data['total'] ?? list.length);
  }

  /// 翻译员详情 — GET /marketplace/translators/:id
  Future<Translator> getTranslatorDetail(String id) async {
    final data = await _client.get('/marketplace/translators/$id');
    return Translator.fromJson(data);
  }

  /// 获取当前译员自己的资料 — GET /translator/profile
  Future<TranslatorProfile?> getMyProfile() async {
    final data = await _client.get('/translator/profile');
    if (data == null) return null;
    return TranslatorProfile.fromJson(data);
  }

  /// 保存/更新当前译员资料 — PUT /translator/profile
  Future<TranslatorProfile> saveMyProfile(TranslatorProfile profile) async {
    final data = await _client.put('/translator/profile', data: profile.toJson());
    return TranslatorProfile.fromJson(data);
  }

  /// POST /translator/profile/dev-approve — api-contract 6.3
  Future<TranslatorProfile> devApproveProfile() async {
    final data = await _client.post('/translator/profile/dev-approve');
    return TranslatorProfile.fromJson(data);
  }

  /// GET /translator/dashboard/stats — 工作台统计卡片
  Future<Map<String, dynamic>> getDashboardStats() async {
    final result = await _client.get('/translator/dashboard/stats');
    return Map<String, dynamic>.from(result);
  }

  /// GET /translator/opportunities — api-contract 6.4
  Future<Map<String, dynamic>> listOpportunities({
    String? city,
    String? industry,
    String? date,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (city != null && city.isNotEmpty) params['city'] = city;
    if (industry != null && industry.isNotEmpty) params['industry'] = industry;
    if (date != null && date.isNotEmpty) params['date'] = date;
    final result = await _client.get('/translator/opportunities', queryParameters: params);
    return Map<String, dynamic>.from(result);
  }

  /// GET /translator/opportunities/:id — api-contract 6.5
  Future<Map<String, dynamic>> getOpportunityDetail(int id) async {
    final result = await _client.get('/translator/opportunities/$id');
    return Map<String, dynamic>.from(result);
  }

  /// GET /translator/quotes — 我的报价记录
  Future<Map<String, dynamic>> listMyQuotes({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (status != null && status.isNotEmpty) params['status'] = status;
    final result = await _client.get('/translator/quotes', queryParameters: params);
    return Map<String, dynamic>.from(result);
  }

  /// POST /translator/quotes — api-contract 6.6
  Future<Map<String, dynamic>> submitQuote(Map<String, dynamic> data) async {
    final result = await _client.post('/translator/quotes', data: data);
    return Map<String, dynamic>.from(result);
  }

  /// GET /translator/orders — api-contract 6.9
  Future<Map<String, dynamic>> listOrders({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (status != null && status.isNotEmpty) params['status'] = status;
    final result = await _client.get('/translator/orders', queryParameters: params);
    return Map<String, dynamic>.from(result);
  }

  /// GET /translator/orders/:id — api-contract 6.10
  Future<Map<String, dynamic>> getOrderDetail(int id) async {
    final result = await _client.get('/translator/orders/$id');
    return Map<String, dynamic>.from(result);
  }

  /// POST /translator/orders/:id/action — api-contract 6.11
  Future<Map<String, dynamic>> orderAction(int orderId, String action) async {
    final result = await _client.post(
      '/translator/orders/$orderId/action',
      data: {'action': action},
    );
    return Map<String, dynamic>.from(result);
  }
}

class TranslatorListResult {
  final List<Translator> list;
  final int total;
  TranslatorListResult({required this.list, required this.total});
}

/// 译员资料 — 对应 architecture.md 4.3 / api-contract.md 6.1
class TranslatorProfile {
  final String realName;
  final String avatar;
  final List<String> languagePairs;
  final List<String> serviceTypes;
  final List<String> industries;
  final List<String> serviceCities;
  final List<String> serviceVenues;
  final Map<String, dynamic> pricingRules;
  final List<String> certificates;
  final String intro;
  final String expoExperience;
  final double? dailyRateAed;
  final double ratingSummary;
  final String auditStatus;

  TranslatorProfile({
    this.realName = '',
    this.avatar = '',
    this.languagePairs = const [],
    this.serviceTypes = const [],
    this.industries = const [],
    this.serviceCities = const [],
    this.serviceVenues = const [],
    this.pricingRules = const {},
    this.certificates = const [],
    this.intro = '',
    this.expoExperience = '',
    this.dailyRateAed,
    this.ratingSummary = 0.0,
    this.auditStatus = 'PENDING_SUBMISSION',
  });

  factory TranslatorProfile.fromJson(Map<String, dynamic> json) {
    return TranslatorProfile(
      realName: json['realName'] ?? '',
      avatar: json['avatar'] ?? '',
      languagePairs: List<String>.from(json['languagePairs'] ?? []),
      serviceTypes: List<String>.from(json['serviceTypes'] ?? []),
      industries: List<String>.from(json['industries'] ?? []),
      serviceCities: List<String>.from(json['serviceCities'] ?? []),
      serviceVenues: List<String>.from(json['serviceVenues'] ?? []),
      pricingRules: Map<String, dynamic>.from(json['pricingRules'] ?? {}),
      certificates: List<String>.from(json['certificates'] ?? []),
      intro: json['intro'] ?? '',
      expoExperience: json['expoExperience'] ?? '',
      dailyRateAed: json['dailyRateAed'] != null ? (json['dailyRateAed'] as num).toDouble() : null,
      ratingSummary: (json['ratingSummary'] ?? 0).toDouble(),
      auditStatus: json['auditStatus'] ?? 'PENDING_SUBMISSION',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'realName': realName,
      'avatar': avatar,
      'languagePairs': languagePairs,
      'serviceTypes': serviceTypes,
      'industries': industries,
      'serviceCities': serviceCities,
      'serviceVenues': serviceVenues,
      'pricingRules': pricingRules,
      'certificates': certificates,
      'intro': intro,
      'expoExperience': expoExperience,
      'dailyRateAed': dailyRateAed,
    };
  }

  TranslatorProfile copyWith({
    String? realName,
    String? avatar,
    List<String>? languagePairs,
    List<String>? serviceTypes,
    List<String>? industries,
    List<String>? serviceCities,
    List<String>? serviceVenues,
    Map<String, dynamic>? pricingRules,
    List<String>? certificates,
    String? intro,
    String? expoExperience,
    double? dailyRateAed,
  }) {
    return TranslatorProfile(
      realName: realName ?? this.realName,
      avatar: avatar ?? this.avatar,
      languagePairs: languagePairs ?? this.languagePairs,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      industries: industries ?? this.industries,
      serviceCities: serviceCities ?? this.serviceCities,
      serviceVenues: serviceVenues ?? this.serviceVenues,
      pricingRules: pricingRules ?? this.pricingRules,
      certificates: certificates ?? this.certificates,
      intro: intro ?? this.intro,
      expoExperience: expoExperience ?? this.expoExperience,
      dailyRateAed: dailyRateAed ?? this.dailyRateAed,
      ratingSummary: ratingSummary,
      auditStatus: auditStatus,
    );
  }
}
