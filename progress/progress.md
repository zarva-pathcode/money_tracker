# Progress — Money Tracker

> File ini berisi status terakhir dari seluruh pekerjaan proyek.
> **WAJIB dibaca** di awal setiap sesi AI dan **WAJIB diupdate** di akhir setiap sesi.

## Current State

- **Branch:** main
- **Last Updated:** 2026-08-20
- **Build Status:** ✅ dart analyze clean (no errors)
- **App Status:** Functional — all core features working

## In Progress

- (none)

## Blocked

- (none)

## Recently Completed (2026-09-04)

- **Fix overspend false-positive (P0)**: 3 file diubah:
  - `lib/utils/period_helper.dart` — `getPeriodEnd` sekarang return `23:59:59` (bukan `00:00:00`), `isInPeriod` pakai date-only comparison → transaksi hari ini tidak lagi kepotong tengah malam.
  - `lib/providers/expense_provider.dart` — `checkShortfall` exclude `category == 'Tabungan'` dari kedua sisi (`periodIncome` & `periodExpenses`) → alokasi tabungan tidak lagi ngurangin saldo belanja periode.
  - `lib/providers/analysis_provider.dart` — `getPeriodIncome` & `getPeriodExpenses` konsisten exclude `Tabungan` → hero card Pemasukan/Pengeluaran periode akurat.
  - `dart analyze` clean (0 error baru).

- **OCR Phase 1 — Receipt Parser Fix**: `lib/utils/receipt_parser.dart` (167→196 baris):
  - **1.1** Tambah 8 keyword anchor: `GRAND`, `TOTAL HARGA`, `TOTAL BELANJA`, `JUMLAH`, `BAYAR`, `KEMBALI`, `NET TOTAL`, `CHARGE` → `docs/plan-ocr-improvement.md`
  - **1.2** Expand window 3→5 baris setelah keyword ditemukan
  - **1.3** Context-aware `_normalizeLine()`: O→0, I→1, B→8 HANYA jika diapit digit → `INDOMARET` tidak jadi `0N0MARET`
  - **1.4** `_extractPrices()` exclude barcode >13 digit, timestamp (`:`), quantity <3 digit tanpa `Rp`
  - **1.5** `_parsePrice()` deteksi format berdasarkan separator TERAKHIR (`15.000,00` vs `15,000.00`) → akurat Indonesian & international
  - `dart analyze` clean (0 error, 1 info pre-existing)

- **OCR Phase 2 — Preprocessing Improvement**: `lib/services/ocr_service.dart` (144→187 baris):
  - **2.1** `_ensureMinWidth()`: gambar < 1000px di-resize 2x → karakter minimal 16x16px untuk MLKit
  - **2.2** `_addWhiteBorder()`: white border 10px di tepi gambar → mencegah MLKit salah crop edge detection
  - **2.3** `img.gaussianBlur(gray, radius: 1)` sebelum binarization → noise reduction untuk struk thermal kabur
  - **2.4** Pass 4 `_preprocessCombined()`: grayscale + blur + bw + contrast + sharpen sekaligus → kasus yang tidak tertangani pass 1-3
  - **2.5** `_hasReadableText()`: ganti `text.length > 10` dengan validasi minimal ada 1 angka terbaca
  - **2.6** Ganti semua `print()` → `debugPrint()` + import `package:flutter/foundation.dart`
  - `dart analyze` No issues found

## Recently Completed (2026-08-20)

- **Notification fix (timezone)**: Rewrite `NotificationService` — 3-tier timezone fallback (IANA → system name → offset-based). Cancel reminder tanpa affect budget alerts (`cancelReminder()` ID base 100 vs `showBudgetAlert()` ID base 200). `rescheduleAll()` sekarang hanya cancel reminders, bukan `cancelAll()`. Detail logging `[NOTIF]` untuk debugging. **✅ Verified on device** — notif muncul di tray sesuai jadwal.
- **OCR improvement plan**: Disimpan di `docs/plan-ocr-improvement.md`. 3 phase: parser fix, preprocessing improvement, UI/UX inline editing.
- **AGENTS.md cleanup**: Pindahkan semua progress data ke `progress/progress.md`. AGENTS.md sekarang hanya berisi rules/instruksi.

---

## Done (Riwayat Lengkap)

### Period Feature
- Added `periodStartDay` to `SettingsProvider` (Hive). Created `PeriodHelper` utility (`getPeriodStart`, `getPeriodEnd`, `isInPeriod`, `formatPeriodRange`). Added period-based getters to `ExpenseProvider`. Modified `checkShortfall` to accept `payDay` parameter. Hero card shows "Saldo Periode" with date range subtitle when `periodStartDay > 1`. Settings screen has "Tanggal Mulai Periode" picker with scroll wheel (1-31) and reset-to-default button. All overspend callers pass `settingsProvider.periodStartDay`.

### Notification Fixes
- Rewrote `NotificationService` — creates channel explicitly with `Importance.max`, uses `areNotificationsEnabled()` for permission check, `scheduleDaily` returns `bool`, icon fixed to `@mipmap/launcher_icon`. `SettingsProvider.updateReminder` separates Hive save from notification scheduling (no rollback). `ReminderSettingsScreen` toggle converted to `StatelessWidget`, reads `rem.isActive` directly from provider.

### Monthly Report Detail Screen
- Converted to `StatefulWidget` with `_showIncome` toggle, dual hero (income + expense + sisa), dual weekly bar chart, top income list, toggle for category distribution (expense/income).

### Home Widget QuickActionWidget
- Emoji icons + category color passed via `fav_cat_N_icon` and `fav_cat_N_color` from `WidgetProvider._syncToWidget()`. Layouts (`widget_layout.xml`, `widget_layout_row.xml`) updated with emoji `TextView`. `QuickActionWidget.kt` sets `setTextViewText` for icon + `setTextColor` for each slot.

### QuickRecentWidget Provider + Layout
- Created `RecentWidgetProvider` (saves balance, period expenses, 15 transactions as JSON). Created `widget_recent_layout.xml` (header with balance/expenses side-by-side, 5 weighted transaction rows, pagination footer with prev/next/voice/add buttons). `ExpenseProvider.loadExpenses()` calls `_syncRecentWidget()` after every operation.

### QuickRecentWidget Complete
- Created `widget_recent_info.xml`, `QuickRecentWidget.kt` (parses JSON, renders 5 rows per page, prev/next pagination via deep links). Registered receiver in `AndroidManifest.xml`. `main.dart` handles `widget?action=page` deep links (save page → update widget) and `voice=true` (auto-trigger STT via `onWidgetVoiceTrigger` callback for warm start, `pendingWidgetUri` for cold start). `main_screen.dart` sets `onWidgetVoiceTrigger = _startRecording`.

### Monthly Report Screen Overflow Fix
- Compacted income/expense toggle from two-icon → single "In/Out" button (~69px). Header layout uses `Row(Expanded + Toggle + MonthPicker)` — subtitle wraps if needed.

### STT Parser Refactor (Data-Driven)
- Replaced petitparser-based clause splitter with monetary-anchor regex splitting (Rightmost Rule + Monetary Weighting). Created `DictionaryService` (singleton, load dictionary.json). Updated `AmountParserService` with `extractRightmost()` that returns amount + remaining text. Rewrote `TextParserService` — split klausa via monetary anchors, stopwords elimination. Rewrote `TransactionParserService` — flow: split → rightmost amount → intent removal → stopwords → infer category → merge same-category. Updated `dictionary.json` dengan separators, monetary_suffixes, unit_words, category_keywords (dari keyword files).

### Lainnya
- Fixed `withOpacity` deprecation → `withValues(alpha:)`.
- Redesigned voice recording overlay.
- Added 'Tabungan' category to Constants + `isSavingsCategory()` helper.
- Added all income chart helpers, income category breakdown, yearly dual bar chart, wealth card, goals summary with net saving.
- STT rp normalization, multi-transaction merge, income pattern detection, slide-up-to-cancel.

### Local Budgeting Alerts
- Added `threshold` field (50-100%) ke `BudgetItem` model + regenerate `.g.dart`. `NotificationService` mendapat channel `budget_alerts_channel` + `showBudgetAlert()` dengan sound+vibration (ID 200+index). `BudgetProvider` memiliki `checkAndNotify()` yang dipicu lewat listener ke `ExpenseProvider`, 3 level notifikasi (threshold kustom, 100%, 120%) dengan anti-spam via Hive (`budget_alert_<kategori>`). `AddBudgetBottomSheet` punya slider threshold 50-100%. `BudgetTab` menampilkan indikator threshold + warna progress bar berdasarkan threshold (orange di threshold, merah di 100%). `SettingsProvider` punya toggle `budgetAlertsEnabled`. `SettingsScreen` punya toggle "Peringatan Anggaran". `main.dart` menghubungkan `BudgetProvider` ↔ `ExpenseProvider` via `linkToExpenseProvider()` dan `addPostFrameCallback`.

---

### Sprint 1 — Selesai
- **Dependency Injection**: `HiveService` dikonversi dari static ke instance-based. Semua provider (`ExpenseProvider`, `PlanProvider`, `BudgetProvider`, `SettingsProvider`, `WidgetProvider`) menerima `HiveService` via constructor DI. `SettingsProvider` dan `WidgetProvider` tidak lagi akses `Hive.box()` langsung. `OnboardingScreen` menggunakan `SettingsProvider` daripada panggil `HiveService` langsung.
- **OverspendService** (`lib/services/overspend_service.dart`): Ekstraksi `calculateProportionalAllocation()` (alokasi proporsional) dan `executeAllocations()` (eksekusi withdrawal) — menghilangkan 3x duplikasi logika overspend di main_screen, add_expense_screen, edit_expense_screen. OverspendBottomSheet menggunakan `OverspendService.calculateProportionalAllocation()`.
- **NumericInputController** (`lib/utils/numeric_input_controller.dart`): Ekstraksi logika keyboard numerik — menghilangkan 4x duplikasi di add_expense_screen, edit_expense_screen, add_plan_screen, add_fund_bottom_sheet. Menangani key press, backspace, cursor adjustment, formatting.
- **Emoji mapping**: Fungsi `_emojiFor` + `_colorHex` dipindahkan ke `Constants.getCategoryEmoji()` + `Constants.colorHex()`. Digunakan oleh `WidgetProvider` dan `RecentWidgetProvider`.

### Sprint 2 — Selesai
- **VoiceTransactionService** (`lib/services/voice_transaction_service.dart`): Ekstraksi logika `calculateNetExpense()` dan `buildExpenses()` dari `main_screen.dart` — menghilangkan 2 duplikasi logika manual STT expense building.
- **TransactionTypeToggle** (`lib/widgets/transaction_type_toggle.dart`): Ekstraksi toggle expense/income reusable widget — menghilangkan duplikasi `_buildTypeToggle()` + `_buildToggleItem()` di add_expense_screen dan edit_expense_screen.
- **CategoryPicker** (`lib/widgets/category_picker.dart`): Ekstraksi grid kategori reusable widget — menghilangkan duplikasi `_buildCategoryItem()` + `AnimatedContainer` + `FaIcon` circle logic di add_expense_screen dan edit_expense_screen.

### Sprint 3 — Selesai
- **AnalysisProvider** (`lib/providers/analysis_provider.dart`): Provider baru untuk semua logika agregasi dan analitik (all-time totals, period balance, chart helpers, income helpers, top transactions, monthly/yearly aggregations). Menerima `ExpenseProvider` via constructor DI dan `addListener(notifyListeners)` untuk sinkronisasi otomatis.
- **ExpenseProvider** ramping: hanya CRUD + filter state + filtered view totals (`balance`, `totalIncome`, `totalExpenses`). Tersisa ~250 baris dari 552.
- **`main.dart`**: `AnalysisProvider` didaftarkan via `ChangeNotifierProvider(create: (ctx) => AnalysisProvider(expenseProvider: ctx.read<ExpenseProvider>()))`.
- **`home_screen.dart`** dan **`montly_report_screen.dart`** diperbarui menggunakan `AnalysisProvider` untuk semua data analitik.

---

## Key Decisions

- **Period formula**: `getPeriodStart(payDay)` returns the most recent payDay occurrence (or clamped to month end). Period runs `[start, start + 1 month - 1 day]`. Edge cases (Feb 28/29, months with < 31 days) handled via `_clampDay`.
- **Wealth formula**: `Total Kekayaan = allTimeBalance + sum(goals.currentAmount)`. All-time balance already reduced by Tabungan expense transactions → no double-count.
- **Notification toggle no rollback**: Hive save always commits; `scheduleDaily` failure shows snackbar but never reverts toggle.
- **Widget icons**: Emoji + category color instead of custom drawables — simpler, recognizable, works on Android 7+.
- **Recent widget pagination**: 3 pages × 5 transactions. Page index stored in SharedPreferences; tap prev/next triggers deep link → Flutter saves new page + `updateWidget`.
- **Overspend split**: Auto-proportional based on goal balances; user edits individual amounts in bottom sheet. Set to 0 → goal excluded; remaining shortfall redistributed.
- **Income in reports**: Income data gets full parity with expense — own donut chart, own breakdown, dual bars in yearly chart, income stats card.
- **Voice loading overlay**: Replaces recording overlay during STT parse + save phase to bridge the millisecond delay gap.
- Cancel direction is slide-UP, with cancel zone visually below the recording card.
- **STT Rightmost Rule**: Amount paling kanan dalam klausa adalah harga (monetary anchor). Angka yang diikuti unit word (botol/pcs) ditolak sebagai monetary. Monetary suffix (ribu/rb/k/juta/jt) mengonfirmasi nominal uang.
- **Merge strategy**: Klausa same-category + same-type di-merge jadi 1 transaksi (title comma-joined, amount summed). Beda category → transaksi terpisah.
- **Threshold alert levels**: 3 level — threshold kustom (warning), 100% (habis), 120% (kelebihan). Anti-spam via Hive `budget_alert_<kategori>` menyimpan persentase terakhir yang di-notify. Reset ke 0 saat pengeluaran turun di bawah threshold.

## Next Steps

1. ~~Test notifikasi end-to-end setelah fix timezone~~ ✅ Verified on device
2. OCR improvement Phase 2: preprocessing (upscaling, noise reduction, white border, combined pass)
3. OCR improvement Phase 3: UI/UX inline editing (amount edit, confidence badge, gunakan teks ini)
4. E2E testing untuk period-based balance dan overspend

## Critical Context

- `parser_constants.dart` uses `static final` initializer (not `const`); full restart required after keyword changes.
- STT (`speech_to_text` v7) typically omits commas/punctuation; rp normalization must run before regex split.
- Overspend check uses current period balance (income - expenses within period); `checkShortfall(amount, payDay: ...)` computes this.
- Edit screen overspend only triggers on delta (newAmount - oldAmount > 0).
- Home widget RemoteViews cannot use scroll, EditText, or microphone. Recent widget uses pagination via deep links + `HomeWidget.updateWidget`.
- `saveWidgetData` stores values in Android SharedPreferences; `QuickRecentWidget.kt` reads them via `widgetData.getString(key)`.

## Relevant Files

- `assets/json/dictionary.json`: Kamus utama — intents, stopwords, separators, monetary_suffixes, unit_words, category_keywords.
- `lib/services/dictionary_service.dart`: Singleton loader dictionary.json, hash lookup O(1) untuk stopword/suffix/category.
- `lib/services/amount_parser_service.dart`: `extractAmount()` (leftmost — backward compat) + `extractRightmost()` (Rightmost Rule + Monetary Weighting).
- `lib/services/text_parser_service.dart`: `splitIntoClauses()` via monetary anchors, `removeStopwords()`.
- `lib/services/transaction_parser_service.dart`: Orchestrator — split → rightmost amount → intent removal → stopwords → infer category → merge same-category.
- `lib/services/voice_transaction_service.dart`: `calculateNetExpense()`, `buildExpenses()` dari hasil ParsedTransaction.
- `lib/providers/recent_widget_provider.dart`: Syncs balance, period expenses, 15 transactions (JSON) to widget SharedPreferences.
- `lib/providers/expense_provider.dart`: `_syncRecentWidget()` called from `loadExpenses()` after every add/edit/delete.
- `lib/providers/widget_provider.dart`: Emoji + color sync for QuickActionWidget.
- `lib/providers/settings_provider.dart`: `periodStartDay`, reminder update (no rollback).
- `lib/utils/period_helper.dart`: Period start/end computation, `isInPeriod`, `formatPeriodRange`.
- `lib/services/notification_service.dart`: Channel creation, permission check, `scheduleDaily` returns bool.
- `lib/screens/reminder_settings_screen.dart`: `_ReminderTileItem` converted to `StatelessWidget`.
- `res/layout/widget_recent_layout.xml`: Header (balance+expenses), 5 transaction rows, pagination footer.
- `res/xml/widget_recent_info.xml`: AppWidgetProvider metadata for QuickRecentWidget.
- `android/.../QuickRecentWidget.kt`: Renders 5 transaction rows per page, pagination + action buttons.
- `res/layout/widget_layout.xml` / `widget_layout_row.xml`: Emoji `TextView` replacing `ImageView` for category slots.
- `android/.../QuickActionWidget.kt`: Sets emoji + text color from `fav_cat_N_icon` / `fav_cat_N_color`.
- `lib/main.dart`: `pendingWidgetUri`, `onWidgetVoiceTrigger`, `_handleWidgetClick` for all deep links.
- `lib/screens/home_screen.dart`: Hero card with period-aware "Saldo Periode".
- `lib/screens/montly_report_screen.dart`: Monthly/yearly tabs, income/expense toggle, dual charts, wealth card.
- `lib/screens/monthly_report_detail_screen.dart`: Dual hero, dual weekly, top income, toggle kategori.
- `lib/widgets/overspend_bottom_sheet.dart`: Goal selection + auto-split + editable amounts.
- `lib/screens/main_screen.dart`: FAB voice recording, processing overlay, slide-up cancel, overspend check, widget voice trigger.
- `lib/providers/plan_provider.dart`: `withdrawFromPlan()`.
- `lib/providers/budget_provider.dart`: Budget allocations state management.
- `lib/utils/constants.dart`: Category styles, `isSavingsCategory()`.
- `lib/utils/parser_constants.dart` + `lib/utils/keywords/` (9 files): STT voice parsing data.
- `lib/utils/category_colors.dart`: Category color mapping.
- `lib/utils/formartters.dart`: Number/date formatting helpers.
- `lib/utils/receipt_parser.dart`: Receipt OCR text parsing logic.
- `lib/services/hive_service.dart`: Centralized Hive CRUD operations.
- `lib/services/export_service.dart`: CSV export logic.
- `lib/services/import_service.dart`: CSV import logic.
- `lib/services/speech_service.dart`: STT recording & transcription.
- `lib/services/amount_parser_service.dart`: Amount extraction from STT text.
- `lib/services/ocr_service.dart`: MLKit document scanning & text recognition.
- `lib/services/text_parser_service.dart`: Generic text parsing.
- `lib/services/transaction_parser_service.dart`: Transaction creation from parsed text.

## Session Log

| Tanggal | Sesi | Yang Dikerjakan | Status |
|---------|------|-----------------|--------|
| 2026-08-20 | Notif Fix | Timezone handling, cancel separation, logging | ✅ Done |
| 2026-08-20 | OCR Plan | Riset + plan penyempurnaan OCR | ✅ Done |
| 2026-08-20 | AGENTS.md | SOLID rules, progress tracking, cleanup | ✅ Done |
| 2026-09-04 | Overspend Fix | Fix false-positive: period end midnight, exclude Tabungan dari checkShortfall & getPeriodIncome/Expenses | ✅ Done |
| 2026-09-04 | Settings Animasi | Tambah import flutter_animate, per-section fadeIn+slideY delay 80ms (0→400ms) sesuai gaya Report | ✅ Done |
| 2026-09-04 | Notif Verify | Notif verified on device — muncul di tray sesuai jadwal, timezone fallback bekerja | ✅ Done |
| 2026-09-04 | OCR Phase 1 | ReceiptParser: 8 keyword anchor, context-aware normalize, extractPrices filter, parsePrice last-sep format | ✅ Done |
| 2026-09-04 | OCR Phase 2 | OcrService: upscaling, white border, gaussian blur, combined pass 4, readable text threshold, print→debugPrint | ✅ Done |
