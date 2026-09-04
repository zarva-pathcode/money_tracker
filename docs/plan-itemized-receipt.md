# Itemized Multi-Item Receipt Scanner

## Tujuan
Mengubah hasil scan struk dari 1 nominal total tunggal menjadi kemampuan membaca **daftar rincian barang per baris** (Nama Barang + Harga + Kategori Otomatis), serta menyediakan layar review checklist interaktif sebelum disimpan ke buku kas sebagai transaksi terpisah.

## Arsitektur & Alur

```
[Camera Scan / MLKit]
        │
        ▼ (Raw OCR Text)
[ReceiptParser.extractLineItems()]  ───▶  [DictionaryService.inferCategory()]
        │                                         │
        ▼ (List<ReceiptItem>)                    │ (Auto-assign Category)
[ReceiptItemsReviewScreen (UI)]  ◀────────────────┘
        │
        ├─▶ [User edits title/price, unchecks unwanted items]
        │
        ▼ (List<Expense>)
[ExpenseProvider.addExpenses(batch)]
        │
        ▼
[HiveService] ───▶ [1x reload & refresh widgets] ───▶ [Home / MainScreen]
```

## Fase Pengerjaan

### Fase 1: Data Layer — Model `ReceiptItem`
- **File baru:** `lib/models/receipt_item.dart`
- **Atribut:**
  - `id` (String — uuid)
  - `name` (String — nama barang bersih tanpa barcode)
  - `price` (double — harga item)
  - `category` (String — kategori hasil tebakan dictionary)
  - `isSelected` (bool — status centang di checklist UI)
  - `quantity` (int — opsional, default 1)

### Fase 2: Logic Layer — Parsing Rincian Item
- **File:** `lib/utils/receipt_parser.dart`
- **Fungsi baru:** `static List<ReceiptItem> extractLineItems(String rawText)`
- **Mekanisme:**
  1. Filter header struk: nama toko, alamat (JL., NO.), NPWP, tanggal/waktu, nomor kasir
  2. Filter footer struk: TOTAL, SUBTOTAL, CASH, KEMBALI, VOUCHER, PPN, TERIMA KASIH
  3. Pembersihan nama produk: hapus awalan barcode/SKU (contoh: `258896 NUVO SABUN` → `Nuvo Sabun`), hapus kuantitas (`2x INDOMIE` → `Indomie`), title case
  4. Penanganan 2 format layout:
     - Format baris sejajar: nama + harga dalam 1 baris
     - Format kolom terpisah: nama di atas, harga di bawah → dipasangkan 1-ke-1
  5. Auto-categorization via `DictionaryService.instance.inferCategory(name, 'expense')`

### Fase 3: State Layer — Batch Save
- **File:** `lib/providers/expense_provider.dart`
- **Method baru:** `Future<void> addExpenses(List<Expense> expenses)`
- Menyimpan N item sekaligus, panggil `loadExpenses()` 1x di akhir (mencegah lag)

### Fase 4: UI Layer — Layar Review Checklist
- **File baru:** `lib/screens/receipt_items_review_screen.dart`
- **Fitur:**
  - Header ringkasan: badge jumlah item, total nominal
  - Scrollable card list per item:
    - Checkbox (uncheck batal simpan)
    - Category icon pill (tap → CategoryPicker modal)
    - TextField editable (nama barang / harga)
    - Delete button
  - Tombol tambah item manual
  - Bottom bar: **"Simpan Semua (X Barang)"** → overspend check → batch save → success → pop

### Fase 5: Integrasi Scan Screen
- **File:** `lib/screens/scan_receipt_screen.dart`
- Tambahkan tombol **"Rincian Barang (N Item)"** sebagai primary action
- Tombol **"Simpan Total Saja (1 Transaksi)"** tetap tersedia

## Edge Cases
1. Typo OCR pada nama produk → editable TextField di review screen
2. Kategori "Lainnya" sebagai default jika tidak ada di dictionary
3. Struk hanya 1 barang → layar review tetap berfungsi
