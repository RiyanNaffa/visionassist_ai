/// Application configuration loaded from dart-define environment variables.
///
/// Run with: `flutter run --dart-define-from-file=.env`
class AppConfig {
  AppConfig._();

  /// Backend proxy base URL (never an LLM key), e.g. `https://abc.ngrok.app`
  /// or `http://10.0.2.2:8000` for the Android emulator. No trailing `/v1`.
  /// Empty = remote features disabled.
  static const String apiProxyUrl = String.fromEnvironment(
    'API_PROXY_URL',
    defaultValue: '',
  );

  /// Shared secret sent to the proxy as `X-API-Key`. Same value as
  /// `PROXY_API_KEY` in the backend `.env`.
  ///
  /// It ships inside the APK, so it only deters casual abuse - it is not a
  /// real credential. The LLM key never leaves the backend.
  static const String proxyApiKey = String.fromEnvironment(
    'PROXY_API_KEY',
    defaultValue: '',
  );

  /// Whether to use the backend for Q&A and ingredient summaries.
  static const bool enableRemoteQa = bool.fromEnvironment(
    'ENABLE_REMOTE_QA',
    defaultValue: false,
  );

  /// Seconds to wait for the backend before falling back to on-device logic.
  static const int remoteTimeoutSeconds = int.fromEnvironment(
    'REMOTE_TIMEOUT_SECONDS',
    defaultValue: 20,
  );

  /// True when every setting needed to reach the backend is present.
  static bool get remoteConfigured =>
      enableRemoteQa && apiProxyUrl.isNotEmpty && proxyApiKey.isNotEmpty;

  /// Default locale for TTS and STT.
  static const String defaultLocale = String.fromEnvironment(
    'DEFAULT_LOCALE',
    defaultValue: 'id-ID',
  );

  /// TTS speech rate (0.0 – 1.0).
  ///
  /// Parsed from the `TTS_SPEECH_RATE` dart-define string at startup.
  /// Falls back to 0.5 when not set or not parseable.
  static double get ttsSpeechRate {
    const raw = String.fromEnvironment('TTS_SPEECH_RATE', defaultValue: '0.5');
    return double.tryParse(raw) ?? 0.5;
  }
}
