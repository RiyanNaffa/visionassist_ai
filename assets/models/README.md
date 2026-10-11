# Currency Detector Model Contract

Place the following file in this directory before building:

| File | Description |
|------|-------------|
| `currency_detector.tflite` | TFLite YOLO detection model (see contract below) |

> **No labels file needed.** Class indices are hard-coded in the detector
> (see `AppConstants.currencyClasses`).

---

## Model

| Property | Value |
|----------|-------|
| Architecture | YOLO v2.6 (end-to-end, single-stage) |
| Task | Object detection |

---

## Model Input

| Property | Value |
|----------|-------|
| Shape | `[1, 256, 256, 3]` |
| Dtype | `float32` |
| Value range | `0.0 – 1.0` (normalised RGB) |
| Channel order | RGB (not BGR) |

The preprocessing pipeline is implemented in pure Dart:
`lib/core/utils/rgb_converter.dart` — `RgbConverter.fromNv21()` / `fromBgra()`.

---

## Model Output

The model outputs a single tensor in YOLO end-to-end format:

| Property | Value |
|----------|-------|
| Shape | `[1, num_detections, 6]` |
| Dtype | `float32` |
| Layout per row | `[cx, cy, w, h, confidence, class_id]` |

- `cx`, `cy`, `w`, `h` are normalised to `[0.0, 1.0]` relative to the
  256 × 256 input.
- `confidence` is a `float32` in `[0.0, 1.0]`.
- `class_id` is a `float32` integer index into `AppConstants.currencyClasses`.
- Rows with `confidence < 0.5` are filtered out before NMS.

Post-processing (NMS threshold 0.45, confidence threshold 0.50) and label
mapping are fully handled in `TfliteCurrencyDetector`.

---

## Classes

Seven classes, **zero-indexed**, Indonesian Rupiah only:

| Index | Class |
|-------|-------|
| 0 | `1000` |
| 1 | `2000` |
| 2 | `5000` |
| 3 | `10000` |
| 4 | `20000` |
| 5 | `50000` |
| 6 | `100000` |

---

## Spoken output

Detections are mapped to Indonesian TTS in
`lib/core/constants/app_strings.dart` via `AppStrings.currencySpeech`:

| Class | Spoken text |
|-------|-------------|
| `1000` | "Seribu Rupiah" |
| `2000` | "Dua ribu Rupiah" |
| `5000` | "Lima ribu Rupiah" |
| `10000` | "Sepuluh ribu Rupiah" |
| `20000` | "Dua puluh ribu Rupiah" |
| `50000` | "Lima puluh ribu Rupiah" |
| `100000` | "Seratus ribu Rupiah" |

When multiple denominations are detected in the same frame, they are
announced in ascending denomination order, joined with a comma:
*"Seribu Rupiah, Dua ribu Rupiah"*.

A new announcement is only made when the **set** of detected denominations
changes from the previous spoken frame.

---

## Training

`ml/train_currency_detector.ipynb` (Google Colab, GPU) trains YOLOv8n on the
IDR dataset, exports to TFLite (float16, int8 fallback) and verifies the
output contract above before you copy the file here.

---

## Without the model

If `currency_detector.tflite` is absent, the app uses
`UnavailableCurrencyDetector` which announces once:
*"Model pendeteksi uang belum dipasang."*

No crash occurs.
