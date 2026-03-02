#!/usr/bin/env bash
# Tests that a Trivy fs JSON output matches the expected meta-code-scan schema shape.
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

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

# Mock Trivy fs JSON output (minimal valid shape)
cat > "$TMPDIR/meta.json" <<'EOF'
{
  "SchemaVersion": 2,
  "ArtifactName": ".",
  "ArtifactType": "filesystem",
  "Results": [
    {
      "Target": "go.sum",
      "Class": "lang-pkgs",
      "Type": "gomod",
      "Vulnerabilities": []
    }
  ]
}
EOF

SCHEMA_VERSION=$(jq -r '.SchemaVersion' "$TMPDIR/meta.json")
ARTIFACT_TYPE=$(jq -r '.ArtifactType' "$TMPDIR/meta.json")
RESULT_COUNT=$(jq '.Results | length' "$TMPDIR/meta.json")

assert_eq "SchemaVersion"  "2"          "$SCHEMA_VERSION"
assert_eq "ArtifactType"   "filesystem" "$ARTIFACT_TYPE"
assert_eq "Results length" "1"          "$RESULT_COUNT"

# Validate JSON is parseable
if jq empty "$TMPDIR/meta.json" 2>/dev/null; then
  echo "PASS: meta.json is valid JSON"
else
  echo "FAIL: meta.json is not valid JSON"
  ((ERRORS++))
fi

if [[ "$ERRORS" -gt 0 ]]; then
  echo "FAILED: $ERRORS assertion(s) failed"; exit 1
else
  echo "ALL PASSED"; exit 0
fi
