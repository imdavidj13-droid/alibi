import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/generated_excuse.dart';

class AlibiStorage {
  static const _historyKey = 'alibi_history';
  static const _favouritesKey = 'alibi_favourites';
  static const _onboardingKey = 'alibi_onboarding_seen';

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

  Future<bool> hasSeenOnboarding() async {
    return await _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    await _prefs.setBool(_onboardingKey, true);
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
