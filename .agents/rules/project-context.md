---
trigger: always_on
---

# 📚 Project Context: Smart Expense Tracker

## 1. Project Overview & Tech Stack
- **Deskripsi:** Aplikasi pencatatan keuangan cerdas dengan fitur pemindaian struk otomatis, voice STT, home widget, dan visualisasi grafik.
- **Sifat Data:** Local-first (Offline).
- **State Management:** `provider` ^6.1.5
- **Local Database:** `hive` + `hive_flutter` (codegen via `hive_generator` + `build_runner`)
- **Charts:** `syncfusion_flutter_charts` ^31.1.19
- **Core AI/Vision Plugins:** `google_mlkit_document_scanner` ^0.4.1, `google_mlkit_text_recognition` ^0.15.1.
- **Speech-to-Text:** `speech_to_text` ^7.0.0.
- **Notifications:** `flutter_local_notifications` ^18.0.1 + `timezone` ^0.10.0.
- **Home Widget:** `home_widget` ^0.9.1.
- **UI/UX Enhancements:** `google_fonts` (Lato), `font_awesome_flutter`, `intl` ^0.20.2.
- **File Handling:** `path_provider`, `permission_handler`, `share_plus`, `file_picker`, `csv`.
- **Text Parsing:** `petitparser` ^6.0.2.
- **Utilities:** `url_launcher`, `image_picker`, `dropdown_button2`.

## 2. Struktur Direktori & Komponen Saat Ini
Berikut adalah daftar file dan folder spesifik yang sudah ada di proyek (berdasarkan eksplorasi `lib/`):

- **`models/` (Data Models):** `budget_item.dart`, `chart_data.dart`, `expense.dart`, `plan_item.dart`.
- **`providers/` (State Layer):** `analysis_provider.dart`, `budget_provider.dart`, `expense_provider.dart`, `plan_provider.dart`, `recent_widget_provider.dart`, `settings_provider.dart`, `widget_provider.dart`.
- **`screens/` (UI Layer):** `add_expense_screen.dart`, `add_plan_screen.dart`, `edit_expense_screen.dart`, `home_screen.dart`, `main_screen.dart`, `monthly_report_detail_screen.dart`, `montly_report_screen.dart`, `onboarding_screen.dart`, `plan_screen.dart`, `reminder_settings_screen.dart`, `scan_receipt_screen.dart`, `settings_screen.dart`.
- **`services/` (Logic & Data Access Layer):** `amount_parser_service.dart`, `export_service.dart`, `hive_service.dart`, `import_service.dart`, `notification_service.dart`, `ocr_service.dart`, `overspend_service.dart`, `speech_service.dart`, `text_parser_service.dart`, `transaction_parser_service.dart`.
- **`themes/` (Style Layer):** `app_theme.dart` (Sentralisasi ThemeData Material 3 & Lato Font).
- **`utils/` (Helper & Logic):** `category_colors.dart`, `constants.dart`, `formartters.dart`, `keywords/` (9 files), `numeric_input_controller.dart`, `parser_constants.dart`, `period_helper.dart`, `receipt_parser.dart`.
- **`widgets/` (Reusable UI Components):** `add_budget_bottom_sheet.dart`, `add_fund_bottom_sheet.dart`, `animated_tap.dart`, `budget_tab.dart`, `category_breakdown.dart`, `category_chip.dart`, `category_picker.dart`, `expense_chart.dart`, `expense_tile.dart`, `filter_bar.dart`, `filter_bottom_sheet.dart`, `modern_input_field.dart`, `month_filter_selector.dart`, `month_picker_button.dart`, `numeric_keyboard.dart`, `overspend_bottom_sheet.dart`, `simple_fab.dart`, `transaction_type_toggle.dart`.

## 3. Arsitektur, Clean Architecture & SOLID Principles (Pemisahan Tugas)
Semua pengembangan dalam aplikasi ini **wajib mematuhi Clean Architecture dan SOLID Principles** berbasis *Layer-Based* yang dikelompokkan secara ketat:
- **`screens/` & `widgets/` (UI Layer):** Hanya untuk antarmuka pengguna (UI). **DILARANG KERAS** menaruh logika perhitungan, pemrosesan gambar MLKit, atau eksekusi *database* di layer ini.
- **`providers/` (State Layer):** Bertugas menyimpan *state* sementara dan menjembatani UI dengan Services. Memanggil fungsi dari *Services*, lalu mengeksekusi `notifyListeners()`.
  - **Aturan Dependency Injection (DI) — SUDAH DITERAPKAN:** Provider menerima `HiveService` via constructor (instance-based, bukan static). `HiveService` dibuat di `main.dart` dan di-inject ke semua provider melalui `MultiProvider`.
- **`services/` & `utils/` (Logic Layer):** Semua operasi dan kalkulasi berat WAJIB diisolasi di sini. 
  - Operasi CRUD *database* -> `hive_service.dart` (instance-based, DI-ready)
  - Logika ekstraksi/baca teks struk -> `receipt_parser.dart`, `ocr_service.dart`, `text_parser_service.dart`, `transaction_parser_service.dart`
  - Parsing suara -> `speech_service.dart`, `amount_parser_service.dart`
  - Overspend alokasi -> `overspend_service.dart`
  - Export/Import CSV -> `export_service.dart` & `import_service.dart`
  - Notifikasi -> `notification_service.dart`

## 4. Aturan Reusable Widgets (UI Consistency)
- **Dilarang Hardcoding:** **DILARANG KERAS** melakukan *hardcoding* properti UI (seperti warna `Colors.blue` atau ukuran teks `fontSize: 16`) di dalam folder `screens/`.
- **Ekstraksi Komponen:** Semua komponen UI yang dipakai lebih dari sekali (seperti tombol, *card*, *textfield*) **WAJIB** diekstrak menjadi file terpisah di folder `widgets/`.
- **Gunakan Tema Sentral:** Warna dan ukuran wajib merujuk secara konsisten pada `utils/constants.dart` atau `ThemeData` bawaan Flutter.

## 5. Optimalisasi & Maintenance (Performance)
- **Const Constructors:** Dalam membangun UI, penggunaan `const` *constructor* **diwajibkan** sebisa mungkin di setiap *widget* untuk mengurangi beban *rebuild* pada Flutter engine.
- **Micro-Rebuilds:** Penggunaan `Consumer` atau `Selector` (dari package Provider) harus **se-spesifik mungkin**. Jangan membungkus seluruh halaman (`Scaffold`) dengan `Consumer` jika hanya satu *text* atau *widget* spesifik yang datanya berubah.

## 6. Aturan Auto-Refactoring (The Scout Rule)
Jika AI ditugaskan mengedit suatu fitur dan menemukan ada logika *database* atau *business logic* rumit yang "bocor" (terletak) di dalam `screens/` atau `providers/`, AI **WAJIB** merapikannya dan memindahkannya ke `services/` yang sesuai **SEBELUM** menambahkan kode fitur yang baru.

### Catatan Refactoring Terbaru
- **HiveService** dikonversi dari static ke instance-based. Provider menerima via constructor DI.
- **OverspendService** dibuat untuk menghilangkan duplikasi logika overspend di 3 screen + alokasi proporsional di widget.
- **NumericInputController** (`utils/numeric_input_controller.dart`) di-ekstrak untuk menghilangkan duplikasi logika keyboard numerik di 4 file (add_expense_screen, edit_expense_screen, add_plan_screen, add_fund_bottom_sheet).
- **Emoji mapping** (`_emojiFor`) dipindahkan ke `Constants.getCategoryEmoji()`; `_colorHex` dipindahkan ke `Constants.colorHex()` — kedua widget (WidgetProvider, RecentWidgetProvider) menggunakan source yang sama.
- **VoiceTransactionService** (`services/voice_transaction_service.dart`) dibuat untuk ekstraksi logika net expense dan build expenses dari hasil STT (dipanggil dari main_screen).
- **TransactionTypeToggle** (`widgets/transaction_type_toggle.dart`) diekstrak dari add/edit expense screen — reusable expense/income toggle widget.
- **CategoryPicker** (`widgets/category_picker.dart`) diekstrak dari add/edit expense screen — reusable category grid widget.
- **AnalysisProvider** (`providers/analysis_provider.dart`) dibuat untuk memisahkan semua logika agregasi dari ExpenseProvider. Menerima ExpenseProvider via constructor DI dan listen otomatis via `addListener(notifyListeners)`. Home screen dan montly report screen menggunakan AnalysisProvider untuk chart data, totals, period balance, top transactions.

## 7. Modifikasi Database Lokal (Hive)
Semua model data di dalam folder `models/` (seperti `expense.dart`) menggunakan fitur *code generation* dari Hive.
- **ATURAN MUTLAK:** AI DILARANG KERAS mengedit *file* berekstensi `.g.dart` secara manual.
- Jika AI memodifikasi atribut di *file* model utama, AI harus selalu menjalankan perintah terminal ini: 
  `dart run build_runner build --delete-conflicting-outputs`

## 8. Penanganan File & Izin Akses (Export/Import CSV)
Karena aturan sistem operasi yang ketat (Scoped Storage Android & iOS Sandbox), AI wajib mematuhi protokol berikut saat menangani file:
- **Izin Akses:** Selalu gunakan `permission_handler` untuk mengecek dan meminta izin *storage/photos* sebelum membaca atau menulis file.
- **Path Aman:** Dilarang menggunakan *hardcoded path*. Selalu gunakan `path_provider` (misal: `getApplicationDocumentsDirectory`) untuk menyimpan file sementara.
- **Share/Export:** Gunakan `share_plus` saat mengekspor CSV agar proses penyimpanan diserahkan ke OS dan lebih aman dari blokir privasi.

## 9. Detail Tanggung Jawab Providers & Services
Agar logika dan state management tetap terpusat, berikut adalah rincian peran masing-masing file:

**Providers (`lib/providers/`):**
- **`analysis_provider.dart`:** Menangani semua logika agregasi dan analitik — all-time totals, period balance, chart helpers (category breakdown, income breakdown, weekly, monthly, yearly), top transactions, income helpers. Menerima `ExpenseProvider` via constructor DI dan otomatis listen via `addListener(notifyListeners)`.
- **`expense_provider.dart`:** Menangani *state* untuk riwayat transaksi (CRUD calls via HiveService, filter state, filter logic). Menyediakan `_expenses` (all) dan `_filteredExpenses` (filtered view) + filtered totals (`balance`, `totalIncome`, `totalExpenses`). Menerima `HiveService` via constructor DI.
- **`plan_provider.dart`:** Menangani *state* untuk goals/tabungan (`plan_item`). CRUD via HiveService, `addFundToPlan`, `withdrawFromPlan`. Menerima `HiveService` via constructor DI.
- **`budget_provider.dart`:** Menangani *state* untuk alokasi dana dan batas anggaran per kategori (`budget_item`). Menerima `HiveService` via constructor DI.
- **`settings_provider.dart`:** Menangani *state* untuk period start day, reminder settings (on/off, time), onboarding status. Semua persistence via `HiveService` (tidak langsung akses Hive box). Menerima `HiveService` via constructor DI.
- **`widget_provider.dart`:** Menangani *state* untuk favorite category di home widget dan sync data ke Android AppWidget via `home_widget`. Menerima `HiveService` via constructor DI.
- **`recent_widget_provider.dart`:** Stateless helper (static methods) untuk sync balance, period expenses, dan 15 transaksi terakhir ke `QuickRecentWidget` via `home_widget`.

**Services (`lib/services/`):**
- **`hive_service.dart`:** Sentralisasi akses *database* lokal (operasi CRUD untuk semua model: Expense, PlanItem, BudgetItem, Settings). **Instance-based** (bukan static) — instance dibuat di `main.dart` dan di-inject ke semua provider.
- **`notification_service.dart`:** Membuat channel notifikasi (Importance.max), cek permission `areNotificationsEnabled()`, `scheduleDaily` (return bool), cancel notifikasi. Masih menggunakan static methods.
- **`speech_service.dart`:** Mengelola STT recording & transcription via `speech_to_text` plugin.
- **`amount_parser_service.dart`:** Mengekstrak jumlah uang dari teks STT (normalisasi "rp", parsing angka).
- **`ocr_service.dart`:** MLKit document scanning & text recognition untuk scan struk.
- **`text_parser_service.dart`:** Generic text parsing utilities.
- **`transaction_parser_service.dart`:** Membuat objek `Expense` dari hasil parsing teks STT.
- **`overspend_service.dart`:** Pure business logic untuk overspend — `calculateProportionalAllocation()` (distribusi proporsional ke goals) dan `executeAllocations()` (eksekusi withdrawal dari goals). Dipanggil dari 3 screen (main, add, edit) dan overspend_bottom_sheet.
- **`export_service.dart`:** Logika konversi dan penyimpanan data aplikasi ke file eksternal (JSON/CSV). Static methods.
- **`import_service.dart`:** Logika pembacaan dan penyisipan data dari file eksternal (JSON/CSV) ke database aplikasi. Static methods.

## 10. Standar Kolaborasi & Version Control (Git Strategy)
Proyek ini dikerjakan secara **SOLO** (Satu Developer, tidak ada tim lain seperti Dika/Jauza). Meskipun demikian, **disiplin Git yang ketat wajib diterapkan**:
- **Isolasi Fitur:** Jika ditugaskan membuat fitur besar (seperti OCR Scanner atau Smart Reminder), AI **WAJIB** mengingatkan dan menyarankan pembuatan Git Branch baru (misal: `git checkout -b feature/ocr-scanner`) sebelum memberikan kode.
- **Lindungi Main Branch:** Jangan biarkan developer mengotori branch `main` dengan eksperimen atau kode setengah jadi. Pastikan integrasi selalu rapi.

## 11. Standar Bahasa
- Semua penjelasan, komentar kode (`//`), dan nama *commit message* wajib menggunakan Bahasa Indonesia.

## 12. Aturan Auto-Maintenance (WAJIB DILAKUKAN AI)
Kamu (AI) bertanggung jawab mutlak untuk menjaga file `project-context.md` ini agar selalu up-to-date.
**Kondisi Trigger:** Setiap kali saya menyuruhmu melakukan salah satu dari hal berikut:
- Membuat file `.dart` baru di dalam folder `providers/`, `services/`, atau `screens/`.
- Menghapus file yang sudah ada.
- Menambahkan library/plugin baru ke dalam `pubspec.yaml`.

**Tindakan:** Kamu **WAJIB** secara otomatis memperbarui file `project-context.md` ini (terutama di bagian Struktur Direktori dan Tech Stack) sebagai bagian dari eksekusi kodemu, tanpa perlu saya suruh atau ingatkan.
