import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PlaySounds {
  PlaySounds._();

  static final FlutterTts _tts = FlutterTts();

  static bool _initialized = false;

  /// INIT

  static Future<void> _init() async {
    if (_initialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    await _tts.setSharedInstance(true);

    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.ambient,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
      IosTextToSpeechAudioMode.voicePrompt,
    );

    _initialized = true;
  }

  /// FROM FCM

  static Future<void> playFromMessage(RemoteMessage message) async {
    final title = message.notification?.title;

    if (title == null || title.isEmpty) return;

    await _init();

    final text = _formatMessage(title);
    await _tts.speak(text);
  }

  /// SIMPLE STRING

  static Future<void> play(String message) async {
    if (message.isEmpty) return;

    await _init();
    await _tts.speak(message);
  }

  /// FORMATTER

  static String _formatMessage(String title) {
    final parts = title.split(' ');

    if (parts.isEmpty) return title;

    // Vehicle number (first word)
    final vehicleRaw = parts.first;
    final vehicleSpelled =
    vehicleRaw.split('').join(' '); // ABC123 -> A B C 1 2 3

    final remaining = parts.length > 1
        ? parts.sublist(1).join(' ')
        : '';

    return 'Alert! $vehicleSpelled. $remaining';
  }
}