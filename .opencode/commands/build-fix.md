---
description: Fix build and compilation errors with minimal changes
---

# Build Fix Command

Fix build and compilation errors with minimal changes: $ARGUMENTS

## Your Task

1. **Run analysis**: `dart analyze`
2. **Collect all errors**
3. **Fix errors one by one** with minimal changes
4. **Verify each fix** doesn't introduce new errors
5. **Run final check** to confirm all errors resolved

## Approach

### DO:
- PASS: Fix type errors with correct types
- PASS: Add missing imports
- PASS: Fix syntax errors
- PASS: Make minimal changes
- PASS: Preserve existing behavior
- PASS: Run `dart analyze` after each change

### DON'T:
- FAIL: Refactor code
- FAIL: Add new features
- FAIL: Change architecture
- FAIL: Use `dynamic` type (unless absolutely necessary)
- FAIL: Add `// ignore:` comments
- FAIL: Change business logic

## Verification Steps

After fixes:
1. `dart analyze` - should show 0 errors
2. `flutter build apk --debug` - should succeed
3. `flutter test` - tests should still pass

---

**IMPORTANT**: Focus on fixing errors only. No refactoring, no improvements, no architectural changes. Get the build green with minimal diff.
