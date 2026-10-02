import 'dart:typed_data';

/// Platform-independent representation of a single camera frame.
class CameraFrame {
  const CameraFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
    required this.format,
    required this.rotationDegrees,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerRow;

  /// Platform image format tag, e.g. 'nv21' or 'bgra8888'.
  final String format;

  /// Clockwise rotation in degrees required to obtain an upright image.
  final int rotationDegrees;
}

/// Abstract contract for the device camera.
abstract class CameraService {
  /// Initialises the camera.  Must be called before any other method.
  Future<void> initialize();

  /// Starts delivering frames via [onFrame].
  ///
  /// Frames are delivered only when a previous frame has been fully consumed
  /// (busy-flag pattern — never queued).
  void startImageStream(void Function(CameraFrame frame) onFrame);

  /// Stops the live image stream without releasing the camera.
  Future<void> stopImageStream();

  /// Captures a still picture and returns the file path.
  ///
  /// The implementation **must** stop the image stream before calling
  /// `takePicture` and restart it afterwards.
  Future<String> takePicture();

  /// Releases all camera resources.
  Future<void> dispose();

  /// Whether the camera is currently streaming frames.
  bool get isStreaming;
}
