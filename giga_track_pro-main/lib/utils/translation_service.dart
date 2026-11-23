import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;

  TranslationService._internal();

  final OnDeviceTranslator _translator = OnDeviceTranslator(
    sourceLanguage: TranslateLanguage.english,
    targetLanguage: TranslateLanguage.urdu,
  );

  // ✅ Simple memory cache to prevent redundant ML model calls
  final Map<String, String> _cache = {};

  Future<String> toUrdu(String text) async {
    if (text.isEmpty) return text;
    
    // Check cache first
    if (_cache.containsKey(text)) {
      return _cache[text]!;
    }

    try {
      final translated = await _translator.translateText(text);
      _cache[text] = translated; // Store in cache
      return translated;
    } catch (e) {
      return text; // Return original if translation fails
    }
  }

  void dispose() {
    _translator.close();
    _cache.clear();
  }
}