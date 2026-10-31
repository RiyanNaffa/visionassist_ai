import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

/// Full-screen gesture area that only counts deliberate swipes.
///
/// A swipe needs both distance and speed. A thumb brushing the screen while
/// holding the phone is fast but short, and must not switch modes or skip a
/// step of the spoken guide.
class SwipeDetector extends StatefulWidget {
  const SwipeDetector({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  /// Minimum travel of a swipe, in logical pixels (about a fifth of a phone
  /// screen's width).
  static const double minDistance = 80;

  /// Minimum speed of a swipe when the finger lifts, in logical pixels per
  /// second.
  static const double minVelocity = 200;

  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  /// When null, vertical drags are left to the child (e.g. to scroll).
  final VoidCallback? onSwipeUp;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;

  @override
  State<SwipeDetector> createState() => _SwipeDetectorState();
}

class _SwipeDetectorState extends State<SwipeDetector> {
  Offset _dragStart = Offset.zero;

  void _onDragStart(DragStartDetails details) =>
      _dragStart = details.globalPosition;

  void _onHorizontalDragEnd(DragEndDetails details) {
    final distance = details.globalPosition.dx - _dragStart.dx;
    final velocity = details.primaryVelocity ?? 0;
    if (distance <= -SwipeDetector.minDistance &&
        velocity <= -SwipeDetector.minVelocity) {
      widget.onSwipeLeft?.call();
    } else if (distance >= SwipeDetector.minDistance &&
        velocity >= SwipeDetector.minVelocity) {
      widget.onSwipeRight?.call();
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final distance = details.globalPosition.dy - _dragStart.dy;
    final velocity = details.primaryVelocity ?? 0;
    if (distance <= -SwipeDetector.minDistance &&
        velocity <= -SwipeDetector.minVelocity) {
      widget.onSwipeUp?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final swipeUp = widget.onSwipeUp != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Measure from where the finger landed, not from where the drag was
      // recognised (after the touch slop).
      dragStartBehavior: DragStartBehavior.down,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onVerticalDragStart: swipeUp ? _onDragStart : null,
      onVerticalDragEnd: swipeUp ? _onVerticalDragEnd : null,
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      child: widget.child,
    );
  }
}
