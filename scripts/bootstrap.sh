#!/usr/bin/env bash
# bootstrap.sh — Scaffold and configure the VisionAssist AI Flutter project.
#
# Usage:
#   cd visionassist_ai
#   bash scripts/bootstrap.sh
#
# What this script does:
#   1. Runs `flutter create` to generate android/ and ios/ platform folders.
#   2. Patches AndroidManifest.xml (permissions, queries, minSdk).
#   3. Patches ios/Runner/Info.plist (usage descriptions).
#   4. Patches ios/Podfile (iOS platform version, permission_handler macros).
#   5. Creates placeholder audio asset files.
#
# Requirements: flutter SDK in PATH, python3 in PATH.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "▶ Scaffolding Flutter project (android + ios)…"
flutter create \
  --platforms=android,ios \
  --org com.visionassist \
  --project-name visionassist_ai \
  .

echo "▶ Running platform patches…"
python3 scripts/tool/patch_platforms.py

echo "▶ Creating placeholder audio assets…"
mkdir -p assets/audio
for cue in beep success mode_switch error; do
  if [ ! -f "assets/audio/${cue}.mp3" ]; then
    # Create a 1-byte placeholder so flutter pub get won't fail.
    printf '\xFF\xFB\x90\x00' > "assets/audio/${cue}.mp3"
    echo "   Created placeholder: assets/audio/${cue}.mp3"
    echo "   ⚠ Replace with a real 44100 Hz 16-bit stereo MP3 cue."
  fi
done

echo "▶ Installing pub dependencies…"
flutter pub get

echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Copy .env.example to .env and fill in API_PROXY_URL."
echo "  2. Add your TFLite model to assets/models/currency_classifier.tflite"
echo "     (see assets/models/README.md for the model contract)."
echo "  3. Replace placeholder audio files in assets/audio/ with real MP3s."
echo "  4. Run: flutter run --dart-define-from-file=.env"
