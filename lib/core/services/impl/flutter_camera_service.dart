import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../camera_service.dart';

/// Concrete [CameraService] backed by the `camera` Flutter plugin.
///
/// Uses [ImageFormatGroup.nv21] on Android and [ImageFormatGroup.bgra8888]
/// on iOS, [ResolutionPreset.medium], audio disabled.
class FlutterCameraService implements CameraService {
  FlutterCameraService();

  CameraController? _controller;
  bool _busy = false;
  bool _streaming = false;

  @override
  bool get isStreaming => _streaming;

  @override
  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No cameras available on this device.');
    }
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final format = Platform.isAndroid
        ? ImageFormatGroup.nv21
        : ImageFormatGroup.bgra8888;

    _controller = CameraController(
      back,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: format,
    );

    await _controller!.initialize();
  }

  @override
  void startImageStream(void Function(CameraFrame frame) onFrame) {
    _assertInitialized();
    if (_streaming) return;
    _streaming = true;
    _controller!.startImageStream((CameraImage image) {
      if (_busy) return; // drop frame – never queue
      _busy = true;
      try {
        final frame = _toCameraFrame(image);
        onFrame(frame);
      } finally {
        _busy = false;
      }
    });
  }

  @override
  Future<void> stopImageStream() async {
    if (!_streaming) return;
    _streaming = false;
    await _controller?.stopImageStream();
  }

  @override
  Future<String> takePicture() async {
    _assertInitialized();
    // Stop stream → capture → restart stream.
    final wasStreaming = _streaming;
    if (wasStreaming) await stopImageStream();
    final file = await _controller!.takePicture();
    if (wasStreaming) {
      // Caller is responsible for calling startImageStream again if needed.
      // This avoids tight coupling to the frame callback.
    }
    return file.path;
  }

  @override
  Future<void> dispose() async {
    _streaming = false;
    await _controller?.dispose();
    _controller = null;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _assertInitialized() {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw StateError('CameraService has not been initialised. '
          'Call initialize() first.');
    }
  }

  CameraFrame _toCameraFrame(CameraImage image) {
    // Flatten all planes into a single byte buffer for downstream consumers.
    final totalBytes =
        image.planes.fold<int>(0, (sum, p) => sum + p.bytes.length);
    final buffer = Uint8List(totalBytes);
    var offset = 0;
    for (final plane in image.planes) {
      buffer.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }

    // Rotation: Android uses sensor orientation; iOS uses device orientation.
    final rotation = _controller!.value.deviceOrientation.index * 90;

    return CameraFrame(
      bytes: buffer,
      width: image.width,
      height: image.height,
      bytesPerRow: image.planes.first.bytesPerRow,
      format: Platform.isAndroid ? 'nv21' : 'bgra8888',
      rotationDegrees: rotation,
    );
  }
}
