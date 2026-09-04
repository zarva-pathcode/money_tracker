---
description: Run verification loop to validate implementation
---

# Verify Command

Run verification loop to validate the implementation: $ARGUMENTS

## Your Task

Execute comprehensive verification:

1. **Analyze**: `dart analyze`
2. **Format Check**: `dart format --set-exit-if-changed .`
3. **Unit Tests**: `flutter test`
4. **Build**: `flutter build apk --debug`
5. **Coverage Check**: `flutter test --coverage && genhtml coverage/lcov.info -o coverage/html`

## Verification Checklist

### Code Quality
- [ ] No Dart analysis errors
- [ ] No format issues
- [ ] No print() / debugPrint() statements (unless intentional)
- [ ] Functions < 50 lines
- [ ] Files < 800 lines

### Tests
- [ ] All tests passing
- [ ] Coverage >= 80%
- [ ] Edge cases covered
- [ ] Error conditions tested

### Security
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] No SQL injection risks
- [ ] No XSS vulnerabilities

### Build
- [ ] Build succeeds
- [ ] No warnings
- [ ] APK size acceptable

## Verification Report

### Summary
- Status: PASS: PASS / FAIL: FAIL
- Score: X/Y checks passed

### Details
| Check | Status | Notes |
|-------|--------|-------|
| Dart Analyze | PASS:/FAIL: | [details] |
| Format | PASS:/FAIL: | [details] |
| Tests | PASS:/FAIL: | [details] |
| Coverage | PASS:/FAIL: | XX% (target: 80%) |
| Build | PASS:/FAIL: | [details] |

### Action Items
[If FAIL, list what needs to be fixed]

---

**NOTE**: Verification loop should be run before every commit and PR.
