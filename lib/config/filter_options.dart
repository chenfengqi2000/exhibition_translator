/// 标准化筛选选项 — 与 shared/enums/filter_options.dart 保持一致
/// 所有值直接以中文存储，筛选时精确匹配

class FilterOptions {
  // ── 服务城市 ──
  static const List<String> cities = ['迪拜', '阿布扎比', '沙迦'];

  // ── 语言能力 ──
  static const List<String> languagePairs = ['中英', '中英阿', '英阿', '中阿'];

  // ── 翻译类型 ──
  static const List<String> serviceTypes = ['陪同翻译', '商务翻译', '会议翻译'];

  // ── 擅长行业 ──
  static const List<String> industries = ['美容展', '建材展', '电子展', '食品展', '能源展'];

  // ── 展会经验 ──
  static const List<String> expoExperience = ['3年以上', '5年以上', '8年以上', '不限'];

  // ── 常驻展馆 ──
  static const List<String> venues = [
    'Dubai World Trade Centre',
    'Dubai Exhibition Centre',
    'Abu Dhabi National Exhibition Centre',
    'Expo Centre Sharjah',
  ];

  FilterOptions._();
}
