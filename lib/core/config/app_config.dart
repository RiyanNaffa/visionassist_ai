/// Application configuration loaded from dart-define environment variables.
///
/// Run with: `flutter run --dart-define-from-file=.env`
class AppConfig {
  AppConfig._();

  /// Backend proxy URL for remote Q&A (never an LLM key).
  static const String apiProxyUrl = String.fromEnvironment(
    'API_PROXY_URL',
    defaultValue: 'https://api.visionassist.example.com',
  );

  /// Whether to enable remote Q&A fallback.
  static const bool enableRemoteQa = bool.fromEnvironment(
    'ENABLE_REMOTE_QA',
    defaultValue: false,
  );

  /// Default locale for TTS and STT.
  static const String defaultLocale = String.fromEnvironment(
    'DEFAULT_LOCALE',
    defaultValue: 'id-ID',
  );

  /// TTS speech rate (0.0 – 1.0).
  static const double ttsSpeechRate = double.fromEnvironment(
    'TTS_SPEECH_RATE',
    defaultValue: 0.5,
  );
}
