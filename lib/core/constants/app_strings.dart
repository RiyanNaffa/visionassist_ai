/// All user-facing strings centralised here.
///
/// Default language: Indonesian (id-ID). English equivalents noted in comments.
class AppStrings {
  AppStrings._();

  // ── App ──────────────────────────────────────────────────────────────────
  static const String appName = 'VisionAssist AI';

  // ── Modes ─────────────────────────────────────────────────────────────────
  static const String modeTextReader = 'Pembaca Teks';
  static const String modeCurrencyDetector = 'Pendeteksi Uang';
  static const String modeIngredientAnalyzer = 'Analisis Bahan';
  static const String modeVisualQa = 'Tanya Gambar';

  static const List<String> modeNames = [
    modeTextReader,
    modeCurrencyDetector,
    modeIngredientAnalyzer,
    modeVisualQa,
  ];

  // ── Gesture hints ─────────────────────────────────────────────────────────
  static const String hintSwipeLeft = 'Geser kiri untuk mode berikutnya';
  static const String hintSwipeRight = 'Geser kanan untuk mode sebelumnya';
  static const String hintDoubleTap = 'Ketuk dua kali untuk mengambil foto';
  static const String hintLongPress = 'Tekan lama untuk bertanya dengan suara';
  static const String hintSingleTap = 'Ketuk untuk jeda atau lanjutkan';

  // ── Permissions ───────────────────────────────────────────────────────────
  static const String permissionCameraTitle = 'Izin Kamera Diperlukan';
  static const String permissionCameraMessage =
      'VisionAssist AI memerlukan akses kamera untuk membaca teks, '
      'mendeteksi uang, dan menjawab pertanyaan visual.';
  static const String permissionCameraRetry = 'Coba Lagi';
  static const String permissionCameraSettings = 'Buka Pengaturan';
  static const String permissionMicTitle = 'Izin Mikrofon Diperlukan';
  static const String permissionMicMessage =
      'Izin mikrofon dibutuhkan untuk fitur Tanya Gambar dengan suara.';

  // ── TTS announcements ─────────────────────────────────────────────────────
  static const String ttsModeSwitch = 'Mode diubah ke ';
  static const String ttsCameraPermissionDenied =
      'Izin kamera ditolak. Ketuk tombol Coba Lagi untuk memberikan izin.';
  static const String ttsCapturing = 'Mengambil foto.';
  static const String ttsProcessing = 'Memproses.';
  static const String ttsNoTextFound = 'Tidak ada teks yang ditemukan.';
  static const String ttsListening = 'Mendengarkan pertanyaan Anda.';
  static const String ttsNotSure =
      'Saya tidak yakin, silakan tanyakan apoteker.';

  // ── Visual Q&A ────────────────────────────────────────────────────────────
  /// Announced after the user double-taps in Visual Q&A mode.
  static const String ttsQaCaptured =
      'Foto diambil. Tekan lama untuk mengajukan pertanyaan.';

  /// Announced when STT returns no speech (query empty).
  static const String ttsQaNoSpeech =
      'Tidak ada suara terdengar. Silakan coba lagi.';

  /// Announced when microphone permission is denied.
  static const String ttsQaMicDenied =
      'Izin mikrofon diperlukan untuk bertanya. '
      'Harap berikan izin di pengaturan perangkat.';

  // ── Currency ──────────────────────────────────────────────────────────────
  static const String ttsCurrencyModelMissing =
      'Model pendeteksi uang belum dipasang. '
      'Silakan ikuti petunjuk di README untuk menambahkan model.';

  /// Short text shown on the status banner when the YOLO model file is absent.
  static const String bannerCurrencyModelMissing =
      '⚠ Model YOLO belum ada.\nLetakkan currency_detector.tflite di assets/models/';

  /// Status banner text while scanning (model loaded, no banknote visible yet).
  static const String bannerCurrencyScanning = 'Arahkan kamera ke uang kertas…';

  /// Maps a denomination class label (e.g. `'20000'`) to its Indonesian
  /// spoken form.  Returns `null` for unknown labels.
  static String? currencySpeech(String classLabel) =>
      _currencySpeechMap[classLabel];

  static const Map<String, String> _currencySpeechMap = {
    '1000': 'Seribu Rupiah',
    '2000': 'Dua ribu Rupiah',
    '5000': 'Lima ribu Rupiah',
    '10000': 'Sepuluh ribu Rupiah',
    '20000': 'Dua puluh ribu Rupiah',
    '50000': 'Lima puluh ribu Rupiah',
    '100000': 'Seratus ribu Rupiah',
  };

  // ── Ingredient / allergen ─────────────────────────────────────────────────
  static const String ttsAllergenPrefix = 'Mengandung: ';
  static const String ttsNoAllergen = 'Tidak ada alergen yang terdeteksi.';
  static const String ttsExpiryPrefix = 'Kadaluarsa: ';
  static const String ttsNoExpiry = 'Tanggal kadaluarsa tidak ditemukan.';

  // ── Quadrant button labels ────────────────────────────────────────────────
  static const String btnPreviousMode = 'Mode Sebelumnya';
  static const String btnNextMode = 'Mode Berikutnya';
  static const String btnCapture = 'Ambil Foto';
  static const String btnAskByVoice = 'Tanya dengan Suara';

  // ── Semantics ─────────────────────────────────────────────────────────────
  static const String semanticsCamera = 'Tampilan kamera langsung';
  static const String semanticsModeStatus = 'Status mode saat ini';
  static const String semanticsResultBanner = 'Hasil analisis';
}
