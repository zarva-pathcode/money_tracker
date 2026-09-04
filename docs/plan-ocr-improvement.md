# Rencana Penyempurnaan Fitur OCR Receipt Scanner

## Kondisi Saat Ini

Pipeline OCR berjalan:
```
Camera (DocumentScanner) → Image Path → 3-pass OCR (original → contrast → binarize)
→ MLKit Latin → Raw Text → ReceiptParser (keyword anchor + price regex) → Total Amount
```

File terkait:
- `lib/services/ocr_service.dart` (144 baris) — MLKit + preprocessing
- `lib/utils/receipt_parser.dart` (167 baris) — parsing total dari teks OCR
- `lib/screens/scan_receipt_screen.dart` (378 baris) — UI scan

### Masalah yang Ditemukan

| Area | Masalah | Dampak |
|------|---------|--------|
| `ocr_service.dart` L68-109 | Preprocessing hanya grayscale + contrast + sharpen. Tidak ada noise reduction, upscaling untuk gambar kecil, atau penanganan gambar miring | Tinggi |
| `ocr_service.dart` L56 | Threshold keberhasilan hanya `text.length > 10` — tidak memvalidasi kualitas teks | Sedang |
| `receipt_parser.dart` L8-21 | Keyword anchor terbatas. Hilang: JUMLAH, TOTAL HARGA, TOTAL BELANJA, BAYAR, KEMBALI, NET TOTAL | Tinggi |
| `receipt_parser.dart` L104-116 | `_normalizeLine()` mengganti SEMUA huruf O→0, I→1, B→8 secara global — merusak teks seperti "INDOMARET" jadi "0N0MARET" | Tinggi |
| `receipt_parser.dart` L125 | Regex `_extractPrices()` terlalu luas — menangkap barcode, nomor HP, quantity, timestamp | Tinggi |
| `receipt_parser.dart` L138-158 | `_parsePrice()` tidak konsisten — deteksi desimal berdasarkan posisi karakter ke-3 dari belakang | Sedang |
| `scan_receipt_screen.dart` | Tidak ada inline editing — user harus "Isi Manual" dari nol jika salah | Sedang |
| `ocr_service.dart` L33,60,84,106 | Menggunakan `print()` bukan `debugPrint()` — violate coding standard | Rendah |

---

## Phase 1: Perbaikan Receipt Parser (Akurasi Parsing)

**Target**: Mengurangi kesalahan identifikasi angka total
**Estimasi**: ~2-3 jam

- [x] **1.1** Tambah keyword anchor yang hilang ke `_keywordVariants`: `JUMLAH`, `TOTAL HARGA`, `TOTAL BELANJA`, `BAYAR`, `KEMBALI`, `NET TOTAL`, `GRAND`, `CHARGE`
- [x] **1.2** Perbaiki logic multi-line total: jika keyword ditemukan tapi tidak ada harga di baris itu, periksa baris berikutnya dengan lebih agresif (expand window dari 3 ke 5 baris)
- [x] **1.3** Perbaiki `_normalizeLine()`: jangan replace huruf O/I/B secara global. Gunakan context-aware correction — hanya di bagian yang terlihat seperti angka (sudah diapit digit)
- [x] **1.4** Perbaiki `_extractPrices()`: tambah negative lookahead untuk mengecualikan barcode (>13 digit), timestamp (mengandung `:`), quantity (<3 digit tanpa prefix Rp)
- [x] **1.5** Perbaiki `_parsePrice()`: deteksi format Indonesia (Rp 15.000,00) vs format internasional (Rp 15,000.00) berdasarkan posisi separator terakhir
- [x] **1.6** Tambahkan filter angka kandidat: exclude angka yang mengandung `:` (waktu), yang >13 digit (barcode), yang <100 (kemungkinan quantity)

---

## Phase 2: Perbaikan OCR Service (Kualitas Gambar)

**Target**: Meningkatkan kualitas input teks dari MLKit
**Estimasi**: ~2-3 jam

- [x] **2.1** Tambahkan upscaling otomatis: jika gambar < 1000px width, resize 2x sebelum OCR (karakter minimal 16x16px untuk MLKit)
- [x] **2.2** Tambahkan noise reduction: Gaussian blur ringan sebelum binarization untuk struk thermal yang kabur/faded
- [x] **2.3** Tambahkan white border (10px) di tepi gambar — mencegah MLKit salah crop edge detection
- [x] **2.4** Tambahkan pass ke-4: combined preprocessing — grayscale + contrast + binarize sekaligus, untuk kasus yang tidak tertangani pass 1-3
- [x] **2.5** Perbaiki threshold keberhasilan: ganti `text.length > 10` dengan validasi minimal ada 1 angka yang terbaca
- [x] **2.6** Ganti `print()` dengan `debugPrint()`

---

## Phase 3: Perbaikan UI/UX Scan Screen

**Target**: Pengalaman lebih baik saat hasil OCR salah
**Estimasi**: ~1-2 jam

- [x] **3.1** Tambahkan inline amount editing: jika total terdeteksi, tampilkan sebagai TextField yang bisa diedit langsung dengan icon edit/checkmark
- [ ] **3.2** Tambahkan tombol "Gunakan Teks Ini": navigasi ke AddExpenseScreen dengan teks OCR mentah sebagai hint (butuh `preFilledNote` di AddExpenseScreen — Phase 3.2 skipped)
- [x] **3.3** Tampilkan indikator confidence: badge hijau/kuning/merah berdasarkan keyword + jumlah angka terbaca

---

## Dependencies

- `google_mlkit_text_recognition: ^0.15.1` — sudah ada
- `image: ^4.5.4` — sudah ada, untuk preprocessing
- `google_mlkit_document_scanner: ^0.4.1` — sudah ada untuk kamera
- Tidak perlu dependency baru

## Risks

- **LOW**: Perubahan `_normalizeLine()` bisa mempengaruhi keyword matching yang sudah ada — perlu di-test ulang
- **LOW**: Perubahan regex `_extractPrices()` bisa miss nominal yang valid — perlu test dengan banyak sample struk
- **MEDIUM**: Tidak ada unit test untuk `ReceiptParser` — setelah perbaikan, wajib tambah test coverage
- **INFO**: MLKit Latin script sudah optimal untuk struk Indonesia — tidak perlu ganti model

## Kompleksitas

**MEDIUM** — Total estimasi 5-8 jam untuk 3 phase. Rekomendasi: mulai Phase 1 (parser) untuk dampak terbesar.
