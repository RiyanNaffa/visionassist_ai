# Currency Classifier Model Contract

Place the following files in this directory before building:

| File | Description |
|------|-------------|
| `currency_classifier.tflite` | TFLite model (see contract below) |
| `currency_labels.txt` | One label per line, matching model output order |

---

## Model Input

| Property | Value |
|----------|-------|
| Shape | `[1, 224, 224, 3]` |
| Dtype | `float32` |
| Value range | `0.0 – 1.0` (normalised RGB) |
| Channel order | RGB (not BGR) |

The preprocessing pipeline is implemented in pure Dart:
`lib/core/utils/rgb_converter.dart` — `RgbConverter.fromNv21()` / `fromBgra()`.

---

## Model Output

| Property | Value |
|----------|-------|
| Shape | `[1, N]` where N = number of labels |
| Dtype | `float32` |
| Activation | Softmax (probabilities sum to 1) |

A prediction is announced only when `confidence ≥ 0.85` across
**3 consecutive frames**.

---

## Labels file (`currency_labels.txt`)

One label per line, zero-indexed to match the output tensor.  
Format: `{CURRENCY_CODE}_{DENOMINATION_VALUE}`

### Required coverage

**Indonesian Rupiah (IDR) — 2016 & 2022 emissions:**

```
IDR_1000
IDR_2000
IDR_5000
IDR_10000
IDR_20000
IDR_50000
IDR_100000
```

**US Dollar (USD):**

```
USD_1
USD_5
USD_10
USD_20
USD_50
USD_100
```

---

## Spoken output format

Labels are mapped to Indonesian spoken text in
`lib/features/currency_detector/presentation/` via `_labelToSpeech()`:

| Label | Spoken text |
|-------|-------------|
| `IDR_1000` | "Seribu Rupiah" |
| `IDR_2000` | "Dua ribu Rupiah" |
| `IDR_5000` | "Lima ribu Rupiah" |
| `IDR_10000` | "Sepuluh ribu Rupiah" |
| `IDR_20000` | "Dua puluh ribu Rupiah" |
| `IDR_50000` | "Lima puluh ribu Rupiah" |
| `IDR_100000` | "Seratus ribu Rupiah" |
| `USD_1` | "Satu Dolar Amerika" |
| `USD_5` | "Lima Dolar Amerika" |
| `USD_10` | "Sepuluh Dolar Amerika" |
| `USD_20` | "Dua puluh Dolar Amerika" |
| `USD_50` | "Lima puluh Dolar Amerika" |
| `USD_100` | "Seratus Dolar Amerika" |

---

## Training recommendations

- Minimum 500 images per denomination per emission year.
- Data augmentation: rotation ±15°, brightness ±30%, perspective warp.
- Validate on held-out set; target top-1 accuracy ≥ 95%.
- Export with `tf.lite.TFLiteConverter.from_saved_model()` with
  `DEFAULT` or `FLOAT16` optimisation.

---

## Without the model

If `currency_classifier.tflite` is absent, the app uses
`UnavailableCurrencyClassifier` which announces once:  
*"Model pendeteksi uang belum dipasang."*

No crash occurs.
