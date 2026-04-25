---
trigger: always_on
---

# 📚 Project Context: Smart Expense Tracker

## 1. Project Overview & Tech Stack
- **Deskripsi:** Aplikasi pencatatan keuangan cerdas dengan fitur pemindaian struk otomatis dan visualisasi grafik.
- **Sifat Data:** Local-first (Offline).
- **State Management:** `provider`
- **Local Database:** `hive`
- **Core AI/Vision Plugins:** `google_mlkit_document_scanner`, `google_mlkit_text_recognition`, `opencv_dart`.

## 2. Struktur Direktori & Komponen Saat Ini
Berikut adalah daftar file dan folder spesifik yang sudah ada di proyek (berdasarkan eksplorasi `lib/`):

- **`models/` (Data Models):** `budget_item.dart`, `chart_data.dart`, `expense.dart`, `plan_item.dart` (termasuk file `.g.dart` hasil code generation Hive).
- **`providers/` (State Layer):** `budget_provider.dart`, `expense_provider.dart`, `plan_provider.dart`.
- **`screens/` (UI Layer):** `add_expense_screen.dart`, `add_plan_screen.dart`, `edit_expense_screen.dart`, `home_screen.dart`, `main_screen.dart`, `monthly_report_detail_screen.dart`, `montly_report_screen.dart`, `onboarding_screen.dart`, `plan_screen.dart`, `scan_receipt_screen.dart`, `settings_screen.dart`.
- **`services/` (Logic & Data Access Layer):** `export_service.dart`, `hive_service.dart`, `import_service.dart`.
- **`utils/` (Helper & Logic):** `category_colors.dart`, `constants.dart`, `formartters.dart`, `image_preprocessor.dart`, `receipt_parser.dart`.
- **`widgets/` (Reusable UI Components):** `add_budget_bottom_sheet.dart`, `add_fund_bottom_sheet.dart`, `animated_tap.dart`, `budget_tab.dart`, `category_breakdown.dart`, `category_chip.dart`, `expense_chart.dart`, `expense_tile.dart`, `filter_bar.dart`, `filter_bottom_sheet.dart`, `month_filter_selector.dart`, `month_picker_button.dart`, `numeric_keyboard.dart`, `simple_fab.dart`.

## 3. Arsitektur & Separation of Concerns (Pemisahan Tugas)
Aplikasi ini menggunakan arsitektur *Layer-Based* yang dikelompokkan berdasarkan tipe *file*. AI WAJIB mematuhi hierarki berikut:
- **`screens/` & `widgets/` (UI Layer):** Hanya untuk antarmuka pengguna (UI). DILARANG KERAS menaruh logika perhitungan, pemrosesan gambar OpenCV/MLKit, atau eksekusi *database* di layer ini.
- **`providers/` (State Layer):** Bertugas menyimpan *state* sementara dan menjembatani UI dengan Services. Memanggil fungsi dari *Services*, lalu `notifyListeners()`.
- **`services/` & `utils/` (Logic Layer):** Semua operasi dan kalkulasi berat WAJIB diisolasi di sini. 
  - Operasi CRUD *database* -> `hive_service.dart`
  - Logika ekstraksi/baca teks struk -> `receipt_parser.dart`
  - Manipulasi/filter gambar -> `image_preprocessor.dart`
  - Export/Import CSV -> `export_service.dart` & `import_service.dart`

## 4. Aturan Auto-Refactoring (The Scout Rule)
Jika AI ditugaskan mengedit suatu fitur dan menemukan ada logika *database* atau *business logic* rumit yang "bocor" (terletak) di dalam `screens/` atau `providers/`, AI WAJIB merapikannya dan memindahkannya ke `services/` yang sesuai SEBELUM menambahkan kode fitur yang baru.

## 5. Modifikasi Database Lokal (Hive)
Semua model data di dalam folder `models/` (seperti `expense.dart`) menggunakan fitur *code generation* dari Hive.
- **ATURAN MUTLAK:** AI DILARANG KERAS mengedit *file* berekstensi `.g.dart` secara manual.
- Jika AI memodifikasi atribut di *file* model utama, AI harus menjalankan atau menyuruh *developer* untuk menjalankan perintah terminal ini: 
  `dart run build_runner build --delete-conflicting-outputs`

## 6. Penanganan File & Izin Akses (Export/Import CSV)
Karena aturan sistem operasi yang ketat (Scoped Storage Android & iOS Sandbox), AI wajib mematuhi protokol berikut saat menangani file:
- **Izin Akses:** Selalu gunakan `permission_handler` untuk mengecek dan meminta izin *storage/photos* sebelum membaca atau menulis file.
- **Path Aman:** Dilarang menggunakan *hardcoded path*. Selalu gunakan `path_provider` (misal: `getApplicationDocumentsDirectory`) untuk menyimpan file sementara.
- **Share/Export:** Gunakan `share_plus` saat mengekspor CSV agar proses penyimpanan diserahkan ke OS dan lebih aman dari blokir privasi.

## 7. Detail Tanggung Jawab Providers & Services
Agar logika dan state management tetap terpusat, berikut adalah rincian peran masing-masing file:

**Providers (`lib/providers/`):**
- **`budget_provider.dart`:** Menangani *state* untuk alokasi dana dan batas anggaran per kategori (`budget_item`).
- **`expense_provider.dart`:** Menangani *state* untuk riwayat transaksi pengeluaran harian dan agregasinya (`expense`).
- **`plan_provider.dart`:** Menangani *state* untuk rencana/target keuangan atau tabungan masa depan (`plan_item`).

**Services (`lib/services/`):**
- **`hive_service.dart`:** Sentralisasi akses *database* lokal (operasi CRUD untuk semua model).
- **`export_service.dart`:** Logika konversi dan penyimpanan data aplikasi ke *file* eksternal (CSV).
- **`import_service.dart`:** Logika pembacaan dan penyisipan data dari *file* eksternal (CSV) ke *database* aplikasi.

## 8. Standar Bahasa
- Semua penjelasan, komentar kode (`//`), dan nama *commit message* wajib menggunakan Bahasa Indonesia.

## 9. Aturan Auto-Maintenance (WAJIB DILAKUKAN AI)
Kamu (AI) bertanggung jawab untuk menjaga file project_context.md ini agar selalu up-to-date.
Kondisi Trigger: Setiap kali saya menyuruhmu melakukan salah satu dari hal berikut:

- Membuat file .dart baru di dalam folder providers/, services/, atau screens/.

- Menghapus file yang sudah ada.

- Menambahkan library/plugin baru ke dalam pubspec.yaml.

Tindakan: Kamu WAJIB secara otomatis memperbarui file project_context.md ini (terutama di bagian Struktur Direktori dan Tech Stack) sebagai bagian dari eksekusi kodemu, tanpa perlu saya suruh atau ingatkan.