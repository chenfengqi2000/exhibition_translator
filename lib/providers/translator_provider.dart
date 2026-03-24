import 'package:flutter/foundation.dart';
import '../models/translator.dart';
import '../services/translator_service.dart';

class TranslatorProvider extends ChangeNotifier {
  final TranslatorService _service;

  List<Translator> _translators = [];
  bool _isLoading = false;
  String? _error;
  int _total = 0;

  TranslatorProfile? _myProfile;
  bool _profileLoading = false;

  TranslatorProvider({required TranslatorService service}) : _service = service;

  TranslatorProfile? get myProfile => _myProfile;
  bool get profileLoading => _profileLoading;

  List<Translator> get translators => _translators;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _total;

  Future<void> loadTranslators({
    String? city,
    String? languagePair,
    String? translationType,
    String? industry,
    String? expoExperience,
    double? budgetMin,
    double? budgetMax,
    bool refresh = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getTranslators(
        city: city,
        languagePair: languagePair,
        translationType: translationType,
        industry: industry,
        expoExperience: expoExperience,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
      );
      _translators = result.list;
      _total = result.total;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Translator?> loadTranslatorDetail(String id) async {
    try {
      return await _service.getTranslatorDetail(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMyProfile() async {
    _profileLoading = true;
    notifyListeners();
    try {
      _myProfile = await _service.getMyProfile();
    } catch (_) {}
    _profileLoading = false;
    notifyListeners();
  }

  Future<bool> saveMyProfile(TranslatorProfile profile) async {
    try {
      _myProfile = await _service.saveMyProfile(profile);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
