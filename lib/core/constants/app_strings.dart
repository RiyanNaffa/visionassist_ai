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
  static const String hintSwipeUp = 'Geser ke atas untuk mendengar panduan';

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
  static const String ttsCameraPermissionPrompt =
      'Aplikasi memerlukan izin kamera. Pilih Izinkan pada jendela yang muncul.';
  static const String ttsCapturing = 'Mengambil foto.';
  static const String ttsProcessing = 'Memproses.';
  static const String ttsNoTextFound = 'Tidak ada teks yang ditemukan.';
  static const String ttsListening = 'Mendengarkan pertanyaan Anda.';
  static const String ttsNotSure =
      'Saya tidak yakin, silakan tanyakan apoteker.';

  // ── Onboarding ────────────────────────────────────────────────────────────
  /// Spoken guide, one entry per step. [screenReader] selects the variant
  /// for TalkBack / VoiceOver users, who get buttons instead of gestures.
  /// Both variants have the same number of steps.
  static List<String> onboardingSteps({required bool screenReader}) =>
      screenReader ? _onboardingButtonSteps : _onboardingGestureSteps;

  static const String _onboardingWelcome =
      'Selamat datang di VisionAssist AI, asisten kamera yang membantu Anda '
      'mengenali tulisan, uang, dan label kemasan dengan suara.';
  static const String _onboardingHold =
      'Pegang ponsel tegak, dengan kamera belakang menghadap benda yang ingin '
      'dikenali.';
  static const String _onboardingTextReader =
      'Mode pertama, $modeTextReader. Arahkan kamera ke tulisan dan tahan '
      'sebentar. Tulisan akan dibacakan begitu gambarnya stabil.';
  static const String _onboardingCurrency =
      'Mode kedua, $modeCurrencyDetector. Arahkan kamera ke uang kertas '
      'Rupiah. Nilai uang akan diucapkan, termasuk jika ada beberapa lembar '
      'sekaligus.';

  static const List<String> _onboardingGestureSteps = [
    '$_onboardingWelcome Geser ke kiri untuk lanjut, geser ke kanan untuk '
        'kembali, ketuk sekali untuk mengulang, atau ketuk dua kali untuk '
        'melewati panduan.',
    '$_onboardingHold Seluruh layar adalah area sentuh, jadi Anda tidak perlu '
        'mencari tombol.',
    'Aplikasi ini punya empat mode: $modeTextReader, $modeCurrencyDetector, '
        '$modeIngredientAnalyzer, dan $modeVisualQa. Geser ke kiri atau ke '
        'kanan untuk berpindah mode. Nama mode diucapkan setiap kali '
        'berpindah.',
    _onboardingTextReader,
    _onboardingCurrency,
    'Mode ketiga, $modeIngredientAnalyzer. Arahkan kamera ke label kemasan, '
        'lalu ketuk dua kali untuk memotret. Anda akan mendengar alergen, '
        'tanggal kedaluwarsa, dan harga.',
    'Mode keempat, $modeVisualQa. Ketuk dua kali untuk memotret, lalu tekan '
        'lama layar dan ucapkan pertanyaan Anda. Jawaban hanya diambil dari '
        'tulisan pada foto.',
    'Ketuk sekali untuk menjeda atau melanjutkan suara. Geser ke atas kapan '
        'saja untuk mendengar panduan ini lagi.',
    'Itu saja. Geser ke kiri atau ketuk dua kali untuk mulai memakai '
        'aplikasi.',
  ];

  static const List<String> _onboardingButtonSteps = [
    '$_onboardingWelcome Pilih tombol $btnOnboardingNext untuk lanjut, '
        '$btnOnboardingPrevious untuk kembali, atau $btnOnboardingSkip untuk '
        'melewati panduan.',
    '$_onboardingHold Selama pembaca layar aktif, aplikasi memakai tombol '
        'besar di bagian bawah layar.',
    'Aplikasi ini punya empat mode: $modeTextReader, $modeCurrencyDetector, '
        '$modeIngredientAnalyzer, dan $modeVisualQa. Pilih tombol '
        '$btnNextMode atau $btnPreviousMode untuk berpindah mode. Nama mode '
        'diucapkan setiap kali berpindah.',
    _onboardingTextReader,
    _onboardingCurrency,
    'Mode ketiga, $modeIngredientAnalyzer. Arahkan kamera ke label kemasan, '
        'lalu pilih tombol $btnCapture. Anda akan mendengar alergen, tanggal '
        'kedaluwarsa, dan harga.',
    'Mode keempat, $modeVisualQa. Pilih tombol $btnCapture, lalu tombol '
        '$btnAskByVoice, dan ucapkan pertanyaan Anda. Jawaban hanya diambil '
        'dari tulisan pada foto.',
    'Pilih tombol $btnGuide kapan saja untuk mendengar panduan ini lagi.',
    'Itu saja. Pilih tombol $btnOnboardingStart untuk mulai memakai '
        'aplikasi.',
  ];

  static const String ttsOnboardingDone = 'Panduan selesai.';
  static const String ttsOnboardingSkipped = 'Panduan dilewati.';
  static const String ttsWelcomeBack =
      'Selamat datang kembali di VisionAssist AI.';
  static const String ttsGuideHintGesture = '$hintSwipeUp.';
  static const String ttsGuideHintButton =
      'Pilih tombol $btnGuide untuk mendengar panduan.';

  /// Announces the active mode, e.g. "Mode Pembaca Teks aktif."
  static String ttsActiveMode(String modeName) => 'Mode $modeName aktif.';

  /// Progress label shown above the step text, e.g. "Langkah 2 dari 9".
  static String onboardingProgress(int step, int total) =>
      'Langkah $step dari $total';

  static const String onboardingGestureHint =
      'Geser kiri: lanjut · Geser kanan: kembali\n'
      'Ketuk: ulangi · Ketuk dua kali: lewati';

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
  static const String btnGuide = 'Panduan';

  // ── Onboarding buttons (screen-reader mode) ───────────────────────────────
  static const String btnOnboardingPrevious = 'Sebelumnya';
  static const String btnOnboardingNext = 'Berikutnya';
  static const String btnOnboardingStart = 'Mulai';
  static const String btnOnboardingSkip = 'Lewati Panduan';
  static const String hintOnboardingPrevious = 'Kembali ke langkah sebelumnya';
  static const String hintOnboardingNext = 'Lanjut ke langkah berikutnya';
  static const String hintOnboardingStart =
      'Tutup panduan dan mulai memakai aplikasi';
  static const String hintOnboardingSkip =
      'Lewati panduan dan mulai memakai aplikasi';

  // ── Semantics ─────────────────────────────────────────────────────────────
  static const String semanticsCamera = 'Tampilan kamera langsung';
  static const String semanticsModeStatus = 'Status mode saat ini';
  static const String semanticsResultBanner = 'Hasil analisis';
}
