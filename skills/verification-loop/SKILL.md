---
name: verification-loop
description: "A comprehensive verification system for Flutter/Dart Claude Code sessions."
origin: ECC
---

# Verification Loop Skill

Sistem verifikasi komprehensif untuk sesi Claude Code di proyek Flutter/Dart.

## When to Use

Invoke this skill:
- Setelah menyelesaikan fitur atau perubahan kode signifikan
- Sebelum membuat PR
- Saat ingin memastikan quality gates terpenuhi
- Setelah refactoring

## Verification Phases

### Phase 1: Build Verification
```bash
# Cek apakah project bisa di-build
flutter build apk --debug 2>&1 | tail -20
# OR (web)
flutter build web 2>&1 | tail -20
```

Jika build gagal, STOP dan perbaiki sebelum lanjut.

### Phase 2: Static Analysis (Type Check + Lint)
```bash
# Dart static analysis — menggantikan tsc + eslint
dart analyze 2>&1 | head -30
# OR
flutter analyze 2>&1 | head -30
```

Laporkan semua error. Perbaiki critical errors sebelum lanjut.

### Phase 3: Format Check
```bash
# Cek formatting Dart
dart format --set-exit-if-changed lib/ test/
```

### Phase 4: Test Suite
```bash
# Run unit tests
flutter test 2>&1 | tail -30

# Run dengan coverage
flutter test --coverage 2>&1 | tail -30
```

Laporkan:
- Total tests: X
- Passed: X
- Failed: X

### Phase 5: Security Scan
```bash
# Cek print() di production code
Select-String -Pattern "^\s*print\(" -Path "lib/**/*.dart" | Select-Object -First 10

# Cek hardcoded secrets/key
Select-String -Pattern "(sk-|api_key|secret|password|token)" -Path "lib/**/*.dart" | Select-Object -First 10
```

### Phase 6: Diff Review
```bash
# Lihat apa yang berubah
git diff --stat
git diff HEAD~1 --name-only
```

Review setiap file yang berubah untuk:
- Perubahan yang tidak diinginkan
- Missing error handling
- Potential edge cases

## Output Format

Setelah menjalankan semua phase, buat verification report:

```
VERIFICATION REPORT
==================

Build:     [PASS/FAIL]
Analyze:   [PASS/FAIL] (X errors, X warnings)
Format:    [PASS/FAIL]
Tests:     [PASS/FAIL] (X/Y passed)
Security:  [PASS/FAIL] (X issues)
Diff:      [X files changed]

Overall:   [READY/NOT READY] for commit

Issues to Fix:
1. ...
2. ...
```

## Continuous Mode

Untuk sesi panjang, jalankan verifikasi setiap 15 menit atau setelah perubahan besar:

```markdown
Checkpoint mental:
- Setelah menyelesaikan setiap function
- Setelah menyelesaikan component/widget
- Sebelum pindah ke task berikutnya

Run: /verify
```

## Integration with Hooks

Skill ini melengkapi PostToolUse hooks dengan verifikasi yang lebih dalam.
Hooks menangkap issues secara langsung; skill ini menyediakan comprehensive review.
