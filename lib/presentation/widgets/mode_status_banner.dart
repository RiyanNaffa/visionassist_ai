import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../controllers/home_controller.dart';

/// Displays the current mode name and latest status/result text.
class ModeStatusBanner extends StatelessWidget {
  const ModeStatusBanner({super.key, required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.semanticsModeStatus,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                state.modeName,
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (state.isProcessing) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ] else if (state.statusText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Semantics(
                label: AppStrings.semanticsResultBanner,
                child: Text(
                  state.statusText,
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (state.isListeningForQuery) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.mic, color: AppColors.primary, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Mendengarkan…',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
