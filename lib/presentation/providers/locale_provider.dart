import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 전체의 Locale 상태를 관리하는 Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  // 기본값은 한국어로 설정
  LocaleNotifier() : super(const Locale('ko')) {
    _loadLocale();
  }

  static const String _prefsKey = 'selected_locale';

  /// 저장된 언어 설정 불러오기
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_prefsKey);

    if (langCode != null) {
      if (langCode == 'zh_Hans') {
        state = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
      } else if (langCode == 'zh_Hant') {
        state = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
      } else {
        state = Locale(langCode);
      }
    }
  }

  /// 언어 변경 및 저장
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();

    // Locale의 구체적인 정보를 문자열로 저장
    String saveValue = locale.languageCode;
    if (locale.scriptCode != null) {
      saveValue = '${locale.languageCode}_${locale.scriptCode}';
    }

    await prefs.setString(_prefsKey, saveValue);
  }
}