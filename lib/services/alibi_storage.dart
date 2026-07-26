import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/generated_excuse.dart';

class AlibiPreferences {
  const AlibiPreferences({
    required this.defaultSituation,
    required this.defaultTone,
    required this.defaultLength,
    required this.safeMode,
  });

  final String defaultSituation;
  final String defaultTone;
  final String defaultLength;
  final bool safeMode;
}

class AlibiStorage {
  static const _historyKey = 'alibi_history';
  static const _favouritesKey = 'alibi_favourites';
  static const _onboardingKey = 'alibi_onboarding_seen';
  static const _defaultSituationKey = 'alibi_default_situation';
  static const _defaultToneKey = 'alibi_default_tone';
  static const _defaultLengthKey = 'alibi_default_length';
  static const _safeModeKey = 'alibi_safe_mode';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<List<GeneratedExcuse>> loadHistory() async {
    return _decode(await _prefs.getStringList(_historyKey));
  }

  Future<List<GeneratedExcuse>> loadFavourites() async {
    return _decode(await _prefs.getStringList(_favouritesKey));
  }

  Future<void> saveHistory(List<GeneratedExcuse> values) async {
    await _prefs.setStringList(
      _historyKey,
      values.take(50).map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> saveFavourites(List<GeneratedExcuse> values) async {
    await _prefs.setStringList(
      _favouritesKey,
      values.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  Future<void> clearFavourites() async {
    await _prefs.remove(_favouritesKey);
  }

  Future<bool> hasSeenOnboarding() async {
    return await _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  Future<void> resetOnboarding() async {
    await _prefs.remove(_onboardingKey);
  }

  Future<AlibiPreferences> loadPreferences() async {
    return AlibiPreferences(
      defaultSituation: await _prefs.getString(_defaultSituationKey) ?? 'Work',
      defaultTone: await _prefs.getString(_defaultToneKey) ?? 'Believable',
      defaultLength: await _prefs.getString(_defaultLengthKey) ?? 'standard',
      safeMode: await _prefs.getBool(_safeModeKey) ?? true,
    );
  }

  Future<void> savePreferences({
    required String defaultSituation,
    required String defaultTone,
    required String defaultLength,
    required bool safeMode,
  }) async {
    await Future.wait([
      _prefs.setString(_defaultSituationKey, defaultSituation),
      _prefs.setString(_defaultToneKey, defaultTone),
      _prefs.setString(_defaultLengthKey, defaultLength),
      _prefs.setBool(_safeModeKey, safeMode),
    ]);
  }

  List<GeneratedExcuse> _decode(List<String>? raw) {
    if (raw == null) return [];
    return raw
        .map(
          (item) => GeneratedExcuse.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .where((item) => item.text.isNotEmpty)
        .toList();
  }
}
