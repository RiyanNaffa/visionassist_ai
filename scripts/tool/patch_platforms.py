#!/usr/bin/env python3
"""patch_platforms.py — Applies required changes to generated android/ and ios/ files.

Run from the project root after `flutter create`:
    python3 scripts/tool/patch_platforms.py
"""

import os
import re
import sys

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


# ── AndroidManifest ─────────────────────────────────────────────────────────

ANDROID_MANIFEST = os.path.join(
    PROJECT_ROOT, "android", "app", "src", "main", "AndroidManifest.xml"
)

ANDROID_PERMISSIONS = """\
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.INTERNET" />

    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService" />
        </intent>
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE" />
        </intent>
    </queries>

"""


def patch_android_manifest():
    if not os.path.exists(ANDROID_MANIFEST):
        print(f"  ⚠ AndroidManifest not found at {ANDROID_MANIFEST}. Skipping.")
        return

    with open(ANDROID_MANIFEST, "r", encoding="utf-8") as f:
        content = f.read()

    if "android.permission.CAMERA" in content:
        print("  ✓ AndroidManifest already patched.")
        return

    # Insert permissions before <application
    content = content.replace(
        "<application", ANDROID_PERMISSIONS + "    <application", 1
    )

    with open(ANDROID_MANIFEST, "w", encoding="utf-8") as f:
        f.write(content)
    print("  ✓ AndroidManifest patched.")


# ── build.gradle (minSdk) ────────────────────────────────────────────────────

BUILD_GRADLE = os.path.join(PROJECT_ROOT, "android", "app", "build.gradle")


def patch_build_gradle():
    if not os.path.exists(BUILD_GRADLE):
        print(f"  ⚠ build.gradle not found at {BUILD_GRADLE}. Skipping.")
        return

    with open(BUILD_GRADLE, "r", encoding="utf-8") as f:
        content = f.read()

    # Replace minSdkVersion with 26.
    patched = re.sub(r"minSdkVersion\s+\d+", "minSdkVersion 26", content)
    patched = re.sub(r"minSdk\s*=\s*\d+", "minSdk = 26", patched)

    if patched == content:
        print("  ✓ build.gradle already has minSdk ≥ 26 (or pattern not found).")
    else:
        with open(BUILD_GRADLE, "w", encoding="utf-8") as f:
            f.write(patched)
        print("  ✓ build.gradle patched (minSdk = 26).")


# ── iOS Info.plist ────────────────────────────────────────────────────────────

INFO_PLIST = os.path.join(PROJECT_ROOT, "ios", "Runner", "Info.plist")

IOS_USAGE_KEYS = """\
\t<key>NSCameraUsageDescription</key>
\t<string>VisionAssist AI memerlukan akses kamera untuk membaca teks, mendeteksi uang, dan menjawab pertanyaan visual.</string>
\t<key>NSMicrophoneUsageDescription</key>
\t<string>Izin mikrofon dibutuhkan untuk fitur Tanya Gambar dengan suara.</string>
\t<key>NSSpeechRecognitionUsageDescription</key>
\t<string>Izin pengenalan suara dibutuhkan untuk fitur pertanyaan berbasis suara.</string>
"""


def patch_info_plist():
    if not os.path.exists(INFO_PLIST):
        print(f"  ⚠ Info.plist not found at {INFO_PLIST}. Skipping.")
        return

    with open(INFO_PLIST, "r", encoding="utf-8") as f:
        content = f.read()

    if "NSCameraUsageDescription" in content:
        print("  ✓ Info.plist already patched.")
        return

    # Insert usage keys before closing </dict>
    content = content.replace("</dict>\n</plist>", IOS_USAGE_KEYS + "</dict>\n</plist>")

    with open(INFO_PLIST, "w", encoding="utf-8") as f:
        f.write(content)
    print("  ✓ Info.plist patched.")


# ── iOS Podfile ───────────────────────────────────────────────────────────────

PODFILE = os.path.join(PROJECT_ROOT, "ios", "Podfile")

PODFILE_PLATFORM = "platform :ios, '15.5'"

PERMISSION_MACROS = """
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_SPEECH_RECOGNIZER=1',
      ]
    end
  end
end
"""


def patch_podfile():
    if not os.path.exists(PODFILE):
        print(f"  ⚠ Podfile not found at {PODFILE}. Skipping.")
        return

    with open(PODFILE, "r", encoding="utf-8") as f:
        content = f.read()

    # Update or insert platform line.
    if re.search(r"platform :ios,", content):
        content = re.sub(r"platform :ios,\s*'[\d.]+'", PODFILE_PLATFORM, content)
    else:
        content = PODFILE_PLATFORM + "\n" + content

    # Append permission macros if not already present.
    if "PERMISSION_CAMERA" not in content:
        # Remove any existing post_install block to avoid duplication.
        content = re.sub(
            r"post_install do \|installer\|.*?^end",
            "",
            content,
            flags=re.DOTALL | re.MULTILINE,
        )
        content = content.rstrip() + "\n" + PERMISSION_MACROS

    with open(PODFILE, "w", encoding="utf-8") as f:
        f.write(content)
    print("  ✓ Podfile patched.")


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("Patching Android…")
    patch_android_manifest()
    patch_build_gradle()

    print("Patching iOS…")
    patch_info_plist()
    patch_podfile()

    print("\nAll patches applied.")


if __name__ == "__main__":
    main()
