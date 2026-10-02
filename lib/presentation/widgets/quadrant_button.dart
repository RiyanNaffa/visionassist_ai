import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';

/// Large quadrant button for screen-reader (accessible) mode.
///
/// Touch target is at least 72 dp per WCAG 2.5.5.
/// Wrapped in [Semantics] with an Indonesian label and hint.
class QuadrantButton extends StatelessWidget {
  const QuadrantButton({
    super.key,
    required this.label,
    required this.semanticsHint,
    required this.onPressed,
    required this.icon,
  });

  final String label;
  final String semanticsHint;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: semanticsHint,
      customSemanticsActions: {
        CustomSemanticsAction(label: label): onPressed,
      },
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.primary, width: 2),
          ),
          minimumSize: const Size(72, 72),
          padding: const EdgeInsets.all(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
