import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';

class TranslationService {
  // 🔑 발급받으신 AIza...로 시작하는 API 키를 여기에 입력하세요.
  static const String _apiKey = 'AIzaSyDy2vyXk8Kr1159SmZRH4es1T6S4j9j0dE';
  static const String _baseUrl = 'https://translation.googleapis.com/language/translate/v2';

  static final _unescape = HtmlUnescape();

  /// 텍스트 번역 실행
  /// [text]: 번역할 원문
  /// [targetLanguage]: 대상 언어 코드 (ko, en, ja, zh-Hans, zh-Hant 등)
  static Future<String?> translateText(String text, String targetLanguage) async {
    if (text.trim().isEmpty) return null;

    try {
      // 💡 Google Translate API 언어 코드 대응
      String lang = targetLanguage;
      if (lang == 'zh_Hans' || lang == 'zh-Hans') lang = 'zh-CN';
      if (lang == 'zh_Hant' || lang == 'zh-Hant') lang = 'zh-TW';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        body: {
          'q': text,
          'target': lang,
          'format': 'text', // 번역 결과에서 HTML 태그를 제외함
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String translatedText = data['data']['translations'][0]['translatedText'];

        // 💡 &quot; 같은 특수문자를 원래 문자로 변환하여 반환
        return _unescape.convert(translatedText);
      } else {
        print('Google Translate API Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Translation Service Exception: $e');
      return null;
    }
  }
}