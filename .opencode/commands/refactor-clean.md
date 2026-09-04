---
description: Remove dead code and consolidate duplicates
---

# Refactor Clean Command

Analyze and clean up the codebase: $ARGUMENTS

## Your Task

1. **Detect dead code** using analysis tools
2. **Identify duplicates** and consolidation opportunities
3. **Safely remove** unused code with documentation
4. **Verify** no functionality broken

## Detection Phase

### Run Analysis Tools

```bash
# Dart analysis (catches unused imports, dead code)
dart analyze

# Find unused files and exports (manual)
# Look for imports without usages in IDE
```

### Manual Checks

- Unused functions (no callers)
- Unused variables and parameters
- Unused imports (dart analyze will flag these)
- Commented-out code
- Unreachable code
- Dead widgets (no longer referenced)

## Removal Phase

### Before Removing

1. **Search for usage** - grep, IDE find references
2. **Check exports** - might be used externally
3. **Verify tests** - no test depends on it
4. **Document removal** - git commit message

### Safe Removal Order

1. Remove unused imports first
2. Remove unused private functions
3. Remove unused public functions
4. Remove unused classes/widgets
5. Remove unused files

## Consolidation Phase

### Identify Duplicates

- Similar functions with minor differences
- Copy-pasted code blocks
- Repeated widget patterns

### Consolidation Strategies

1. **Extract utility function** - for repeated logic
2. **Create shared widget** - for repeated UI patterns
3. **Use mixins/extensions** - for shared behavior
4. **Create shared constants** - for magic values
5. **Extract service method** - for repeated data logic

## Verification

After cleanup:

1. `dart analyze` - no new errors
2. `flutter test` - all tests pass
3. `flutter build apk --debug` - builds successfully
4. Manual smoke test - features work

## Report Format

```
Dead Code Analysis
=================

Removed:
- file.dart: functionName (unused)
- utils.dart: helperFunction (no callers)

Consolidated:
- formatCurrency() and formatNumber() → NumberFormatter utility

Remaining (manual review needed):
- old_widget.dart: potentially unused, verify with team
```

---

**CAUTION**: Always verify before removing. When in doubt, ask or add `// TODO: verify usage` comment.
