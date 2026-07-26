import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alibi_theme.dart';

class AlibiThemeController extends ChangeNotifier {
  static const _storageKey = 'alibi_theme_choice';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  AlibiThemeChoice _choice = AlibiThemeChoice.red;
  AlibiThemeChoice get choice => _choice;

  Future<void> load() async {
    final stored = await _prefs.getString(_storageKey);
    _choice = AlibiThemeChoice.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => AlibiThemeChoice.red,
    );
    notifyListeners();
  }

  Future<void> setChoice(AlibiThemeChoice choice) async {
    if (_choice == choice) return;
    _choice = choice;
    notifyListeners();
    await _prefs.setString(_storageKey, choice.name);
  }
}
