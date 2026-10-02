import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../domain/entities/currency_prediction.dart';
import '../../domain/repositories/currency_classifier.dart';

/// TFLite-backed [CurrencyClassifier].
///
/// Loads `assets/models/currency_classifier.tflite` and
/// `assets/models/currency_labels.txt` from the bundle.
class TfliteCurrencyClassifier implements CurrencyClassifier {
  TfliteCurrencyClassifier();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _available = false;

  /// Initialises the interpreter and loads labels.
  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'models/currency_classifier.tflite',
      );
      final labelsData = await rootBundle.loadString(
        'assets/models/currency_labels.txt',
      );
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      _available = true;
    } catch (e) {
      debugPrint('[CurrencyClassifier] Failed to load model: $e');
      _available = false;
    }
  }

  @override
  bool get isAvailable => _available;

  @override
  Future<CurrencyPrediction> classify(Float32List input) async {
    if (!_available || _interpreter == null) {
      return const CurrencyPrediction(label: 'UNAVAILABLE', confidence: 0.0);
    }

    // Build input as a nested list: [1][224][224][3]
    final inputNested = _buildInputNested(input);
    final outputSize = _labels.length;
    final outputBuffer = [List<double>.filled(outputSize, 0.0)];

    _interpreter!.runForMultipleInputs([inputNested], {0: outputBuffer});

    final scores = outputBuffer[0];
    var maxScore = 0.0;
    var maxIndex = 0;

    for (var i = 0; i < scores.length; i++) {
      final s = scores[i];
      if (s > maxScore) {
        maxScore = s;
        maxIndex = i;
      }
    }

    final label = maxIndex < _labels.length ? _labels[maxIndex] : 'UNKNOWN';
    return CurrencyPrediction(label: label, confidence: maxScore);
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  /// Reshapes flat Float32List into a nested [1][224][224][3] list.
  List<List<List<List<double>>>> _buildInputNested(Float32List flat) {
    const h = 224, w = 224, c = 3;
    return List.generate(
      1,
      (_) => List.generate(
        h,
        (y) => List.generate(
          w,
          (x) => List.generate(
            c,
            (ch) => flat[(y * w + x) * c + ch].toDouble(),
          ),
        ),
      ),
    );
  }

  /// Releases interpreter resources.
  void dispose() => _interpreter?.close();
}

/// Fallback classifier used when the TFLite model file is absent.
///
/// Announces the missing model once, then stays silent.
class UnavailableCurrencyClassifier implements CurrencyClassifier {
  bool _announced = false;

  @override
  bool get isAvailable => false;

  @override
  Future<CurrencyPrediction> classify(Float32List input) async {
    if (!_announced) {
      _announced = true;
      // The controller will check isAvailable and speak the message.
    }
    return const CurrencyPrediction(label: 'UNAVAILABLE', confidence: 0.0);
  }
}
