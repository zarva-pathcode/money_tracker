## Goal
- Unify income/expense with savings goals, build smart overspend protection, revamp reporting with income analytics and wealth tracking, support user-configurable financial period (pay cycle), fix notifications for release builds, and add home widgets with proper category icons.

## Tech Stack
- **Framework:** Flutter (SDK ^3.7.2)
- **State Management:** `provider` ^6.1.5
- **Local Database:** `hive` + `hive_flutter` (codegen via `hive_generator` + `build_runner`)
- **Charts:** `syncfusion_flutter_charts` ^31.1.19
- **AI/Vision:** `google_mlkit_document_scanner` ^0.4.1, `google_mlkit_text_recognition` ^0.15.1
- **Speech-to-Text:** `speech_to_text` ^7.0.0
- **Notifications:** `flutter_local_notifications` ^18.0.1 + `timezone` ^0.10.0
- **Home Widget:** `home_widget` ^0.9.1 (platform channel ke Android AppWidget)
- **Localization/Formatting:** `intl` ^0.20.2
- **Fonts:** `google_fonts` (Lato), `font_awesome_flutter`
- **File Handling:** `path_provider`, `permission_handler`, `share_plus`, `file_picker`, `csv`
- **Text Parsing:** `petitparser` ^6.0.2
- **Utilities:** `url_launcher`, `image_picker`, `dropdown_button2`

## Constraints & Preferences
- **Period system**: `periodStartDay` stored in Hive settings box (default 1 = calendar month). When > 1, hero card shows "Saldo Periode" with date range instead of "Saldo Bulanan".
- Periodic overspend check uses period-based balance (respects custom `payDay`).
- 2-layer total: Saldo Periode/Bulanan (filtered) + Total Kekayaan (all-time balance + goals).
- Savings allocations (addFundToPlan) automatically create an Expense record in 'Tabungan' category so balance reflects available cash.
- Overspend auto-split proportionally across goals but user can edit per-goal amounts.
- Overspend check applies to all 3 entry points: manual add, voice STT, edit (delta).
- Reporting must show both income and expense, with dual bar charts and wealth card.
- "rp" prefix on numbers must be normalized before any regex matching.
- All static keyword/intent/pattern data must be in separated files for maintainability.
- **Notification toggle** must not roll back on scheduling failure — Hive save is independent of notification.
- **Home widget icons** use emoji + category color instead of static drawables; passed via `saveWidgetData`.
- **QuickRecentWidget** shows 5 transaction rows per page with pagination (3 pages), header balance+expenses, and action buttons (voice, add).
- Voice record cannot be done directly from widget; opens app via `expenseTracker://add?voice=true`.
- RemoteViews cannot support scrollable lists, EditText input, or microphone access.

## Arsitektur & Clean Architecture

### Layer-Based Separation (WAJIB)
Semua pengembangan wajib mematuhi Clean Architecture dan SOLID Principles berbasis layer:

- **`screens/` & `widgets/` (UI Layer):** Hanya untuk antarmuka pengguna. **DILARANG** menaruh logika perhitungan, pemrosesan gambar/MLKit, atau eksekusi database di layer ini.
- **`providers/` (State Layer):** Menyimpan state sementara dan menjembatani UI dengan Services. Memanggil fungsi dari Services, lalu `notifyListeners()`.
  - **Dependency Injection (DI):** Provider **TIDAK BOLEH** menginisiasi Service-nya sendiri. Service harus di-inject melalui **constructor** agar mudah di-mock saat testing.
- **`services/` & `utils/` (Logic Layer):** Semua operasi dan kalkulasi berat WAJIB diisolasi di sini.
  - CRUD database → `hive_service.dart`
  - Parsing struk → `receipt_parser.dart`, `ocr_service.dart`, `text_parser_service.dart`, `transaction_parser_service.dart`
  - Parsing suara → `speech_service.dart`, `amount_parser_service.dart`
  - Export/Import CSV → `export_service.dart` & `import_service.dart`
  - Notifikasi → `notification_service.dart`

### The Scout Rule (Auto-Refactoring)
Jika menemukan logika database atau business logic yang "bocor" (terletak) di `screens/` atau `providers/`, **WAJIB** memindahkannya ke `services/` yang sesuai **SEBELUM** menambahkan kode fitur baru.

## Code Conventions & Rules

### Const Constructors
Gunakan `const` constructor semaksimal mungkin di setiap widget untuk mengurangi beban rebuild Flutter engine.

### Micro-Rebuilds (Provider)
Gunakan `Consumer` atau `Selector` **sespesifik mungkin**. Jangan membungkus seluruh `Scaffold` dengan `Consumer` jika hanya satu widget spesifik yang berubah.

### No Hardcoding UI
**DILARANG** hardcode properti UI (warna `Colors.blue`, `fontSize: 16`) di folder `screens/`. Semua komponen UI yang dipakai lebih dari sekali **WAJIB** diekstrak ke `widgets/`. Warna dan ukuran wajib merujuk ke `utils/constants.dart` atau `ThemeData`.

### Hive Code Generation
- **DILARANG** mengedit file `.g.dart` secara manual.
- Jika memodifikasi atribut di model utama, jalankan:
  `dart run build_runner build --delete-conflicting-outputs`

### Export/Import CSV Protocol
- Selalu gunakan `permission_handler` untuk cek & minta izin sebelum baca/tulis file.
- Dilarang hardcode path. Gunakan `path_provider` (`getApplicationDocumentsDirectory`).
- Gunakan `share_plus` saat mengekspor CSV agar penyimpanan ditangani OS.

### Standar Bahasa
Semua penjelasan, komentar kode (`//`), dan commit message wajib menggunakan **Bahasa Indonesia**.

### Git Strategy
Proyek dikerjakan secara **SOLO**. Disiplin Git tetap wajib:
- Fitur besar (OCR, Smart Reminder, dll) sarankan branch baru: `git checkout -b feature/nama-fitur`.
- Jangan biarkan branch `main` terisi kode setengah jadi.

## Auto-Maintenance
AI bertanggung jawab menjaga file `.agents/rules/project-context.md` agar selalu up-to-date.
**Trigger:** Setiap kali membuat file `.dart` baru di `providers/`, `services/`, `screens/`, menghapus file, atau menambah library ke `pubspec.yaml`.
**Tindakan:** Wajib otomatis memperbarui `project-context.md` tanpa perlu diingatkan.

## Progress
### Done
- **Period feature**: Added `periodStartDay` to `SettingsProvider` (Hive). Created `PeriodHelper` utility (`getPeriodStart`, `getPeriodEnd`, `isInPeriod`, `formatPeriodRange`). Added period-based getters to `ExpenseProvider`. Modified `checkShortfall` to accept `payDay` parameter. Hero card shows "Saldo Periode" with date range subtitle when `periodStartDay > 1`. Settings screen has "Tanggal Mulai Periode" picker with scroll wheel (1-31) and reset-to-default button. All overspend callers pass `settingsProvider.periodStartDay`.
- **Notification fixes**: Rewrote `NotificationService` — creates channel explicitly with `Importance.max`, uses `areNotificationsEnabled()` for permission check, `scheduleDaily` returns `bool`, icon fixed to `@mipmap/launcher_icon`. `SettingsProvider.updateReminder` separates Hive save from notification scheduling (no rollback). `ReminderSettingsScreen` toggle converted to `StatelessWidget`, reads `rem.isActive` directly from provider.
- **Monthly report detail screen**: Converted to `StatefulWidget` with `_showIncome` toggle, dual hero (income + expense + sisa), dual weekly bar chart, top income list, toggle for category distribution (expense/income).
- **Home widget QuickActionWidget**: Emoji icons + category color passed via `fav_cat_N_icon` and `fav_cat_N_color` from `WidgetProvider._syncToWidget()`. Layouts (`widget_layout.xml`, `widget_layout_row.xml`) updated with emoji `TextView`. `QuickActionWidget.kt` sets `setTextViewText` for icon + `setTextColor` for each slot.
- **QuickRecentWidget provider + layout**: Created `RecentWidgetProvider` (saves balance, period expenses, 15 transactions as JSON). Created `widget_recent_layout.xml` (header with balance/expenses side-by-side, 5 weighted transaction rows, pagination footer with prev/next/voice/add buttons). `ExpenseProvider.loadExpenses()` calls `_syncRecentWidget()` after every operation.
- **QuickRecentWidget complete**: Created `widget_recent_info.xml`, `QuickRecentWidget.kt` (parses JSON, renders 5 rows per page, prev/next pagination via deep links). Registered receiver in `AndroidManifest.xml`. `main.dart` handles `widget?action=page` deep links (save page → update widget) and `voice=true` (auto-trigger STT via `onWidgetVoiceTrigger` callback for warm start, `pendingWidgetUri` for cold start). `main_screen.dart` sets `onWidgetVoiceTrigger = _startRecording`.
- **Monthly report screen overflow fix**: Compacted income/expense toggle from two-icon → single "In/Out" button (~69px). Header layout uses `Row(Expanded + Toggle + MonthPicker)` — subtitle wraps if needed.
- Fixed `withOpacity` deprecation → `withValues(alpha:)`.
- Redesigned voice recording overlay.
- Added 'Tabungan' category to Constants + `isSavingsCategory()` helper.
- Added all income chart helpers, income category breakdown, yearly dual bar chart, wealth card, goals summary with net saving.
- STT rp normalization, multi-transaction merge, income pattern detection, slide-up-to-cancel.

### In Progress
- (none)

### Blocked
- (none)

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
- **`home_screen.dart`** dan **`montly_report_screen.dart`** diperbarui menggunakan `AnalysisProvider` untuk semua data analitik. `_buildHeroCard`, `_buildWealthCard`, `_buildGoalsSummary`, `_buildUnifiedCategoryAnalysis`, `_buildIncomeCategoryBreakdown`, `_prepareChartData`/`_prepareIncomeChartData` menggunakan `analysisProvider` dari `context.read()`.

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

## Next Steps
- Test all flows end-to-end (especially period-based balance, overspend with custom payDay, and widget interactions).

## Critical Context
- `parser_constants.dart` uses `static final` initializer (not `const`); full restart required after keyword changes.
- STT (`speech_to_text` v7) typically omits commas/punctuation; rp normalization must run before regex split.
- Overspend check uses current period balance (income - expenses within period); `checkShortfall(amount, payDay: ...)` computes this.
- Edit screen overspend only triggers on delta (newAmount - oldAmount > 0).
- Home widget RemoteViews cannot use scroll, EditText, or microphone. Recent widget uses pagination via deep links + `HomeWidget.updateWidget`.
- `saveWidgetData` stores values in Android SharedPreferences; `QuickRecentWidget.kt` reads them via `widgetData.getString(key)`.

## Relevant Files
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
