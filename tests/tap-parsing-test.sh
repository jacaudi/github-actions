#!/usr/bin/env bash
set -euo pipefail

# Create mock TAP output matching node --test format
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/output.txt" << 'EOF'
TAP version 13
# Subtest: test-math.js
ok 1 - addition works
ok 2 - subtraction works
not ok 3 - division by zero
ok 4 - multiplication works
1..4
# tests 56
# pass 54
# fail 1
# cancelled 0
# skipped 1
# todo 0
# duration_ms 312
EOF

# Initialize variables (mirrors test.yml)
PASSED=0
FAILED=0
SKIPPED=0
TOTAL=0
DURATION=""

# --- TAP parsing logic under test ---
if grep -qE "^# tests [0-9]+" "$TMPDIR/output.txt"; then
  PASSED=$(grep -oE "^# pass [0-9]+" "$TMPDIR/output.txt" | grep -oE "[0-9]+" | head -1) || PASSED=0
  FAILED=$(grep -oE "^# fail [0-9]+" "$TMPDIR/output.txt" | grep -oE "[0-9]+" | head -1) || FAILED=0
  SKIPPED=$(grep -oE "^# skipped [0-9]+" "$TMPDIR/output.txt" | grep -oE "[0-9]+" | head -1) || SKIPPED=0
  TOTAL=$(grep -oE "^# tests [0-9]+" "$TMPDIR/output.txt" | grep -oE "[0-9]+" | head -1) || TOTAL=0
  DURATION=$(grep -oE "^# duration_ms [0-9]+" "$TMPDIR/output.txt" | grep -oE "[0-9]+" | head -1 | xargs -I{} echo "{}ms") || DURATION=""
fi

# --- Assertions ---
ERRORS=0

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: $name: expected '$expected', got '$actual'"
    ((ERRORS++))
  else
    echo "PASS: $name = $actual"
  fi
}

assert_eq "PASSED"   "54"    "$PASSED"
assert_eq "FAILED"   "1"     "$FAILED"
assert_eq "SKIPPED"  "1"     "$SKIPPED"
assert_eq "TOTAL"    "56"    "$TOTAL"
assert_eq "DURATION" "312ms" "$DURATION"

# Status logic (mirrors test.yml)
if [[ "$FAILED" -gt 0 ]]; then
  STATUS="failed"
elif [[ "$PASSED" -gt 0 ]]; then
  STATUS="passed"
else
  STATUS="unknown"
fi

assert_eq "STATUS" "failed" "$STATUS"

# Test all-pass scenario
cat > "$TMPDIR/output-pass.txt" << 'EOF'
# tests 56
# pass 56
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 312
EOF

PASSED=0; FAILED=0; SKIPPED=0; TOTAL=0; DURATION=""

if grep -qE "^# tests [0-9]+" "$TMPDIR/output-pass.txt"; then
  PASSED=$(grep -oE "^# pass [0-9]+" "$TMPDIR/output-pass.txt" | grep -oE "[0-9]+" | head -1) || PASSED=0
  FAILED=$(grep -oE "^# fail [0-9]+" "$TMPDIR/output-pass.txt" | grep -oE "[0-9]+" | head -1) || FAILED=0
  SKIPPED=$(grep -oE "^# skipped [0-9]+" "$TMPDIR/output-pass.txt" | grep -oE "[0-9]+" | head -1) || SKIPPED=0
  TOTAL=$(grep -oE "^# tests [0-9]+" "$TMPDIR/output-pass.txt" | grep -oE "[0-9]+" | head -1) || TOTAL=0
  DURATION=$(grep -oE "^# duration_ms [0-9]+" "$TMPDIR/output-pass.txt" | grep -oE "[0-9]+" | head -1 | xargs -I{} echo "{}ms") || DURATION=""
fi

if [[ "$FAILED" -gt 0 ]]; then
  STATUS="failed"
elif [[ "$PASSED" -gt 0 ]]; then
  STATUS="passed"
else
  STATUS="unknown"
fi

assert_eq "PASSED (all-pass)"   "56"     "$PASSED"
assert_eq "FAILED (all-pass)"   "0"      "$FAILED"
assert_eq "TOTAL (all-pass)"    "56"     "$TOTAL"
assert_eq "STATUS (all-pass)"   "passed" "$STATUS"
assert_eq "DURATION (all-pass)" "312ms"  "$DURATION"

if [[ "$ERRORS" -gt 0 ]]; then
  echo ""
  echo "FAILED: $ERRORS assertion(s) failed"
  exit 1
else
  echo ""
  echo "ALL PASSED"
  exit 0
fi
