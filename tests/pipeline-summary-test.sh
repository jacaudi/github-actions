#!/usr/bin/env bash
# Tests the pipeline-summary merge script in isolation.
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

ERRORS=0

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: $name: expected '$expected', got '$actual'"
    ((ERRORS++)) || true
  else
    echo "PASS: $name = $actual"
  fi
}

# Set up mock artifact directories (as download-artifact creates them)
mkdir -p "$TMPDIR/meta-artifacts/pipeline-meta-code-scan"
mkdir -p "$TMPDIR/meta-artifacts/pipeline-meta-build-artifact"
# Note: test-artifact intentionally absent to test did-not-run behavior

cat > "$TMPDIR/meta-artifacts/pipeline-meta-code-scan/meta.json" <<'EOF'
{
  "SchemaVersion": 2,
  "ArtifactName": ".",
  "ArtifactType": "filesystem",
  "Results": []
}
EOF

cat > "$TMPDIR/meta-artifacts/pipeline-meta-build-artifact/meta.json" <<'EOF'
{
  "block": "build-artifact",
  "status": "passed",
  "timestamp": "2026-03-01T00:00:00Z",
  "digest": "sha256:abc123"
}
EOF

# Run the merge script
python3 - <<PYEOF
import json, os, pathlib

meta_dir = pathlib.Path("$TMPDIR/meta-artifacts")

expected_blocks = [
    "code-scan",
    "build-artifact",
    "test-artifact",
    "scan-artifact",
    "release-gate",
    "semantic-release",
    "helm-publish",
    "webhook",
]

merged = {
    "pipeline_id": "test-run-123",
    "run_number": "1",
    "repository": "owner/repo",
    "commit": "abc123",
    "ref": "refs/heads/main",
    "workflow": "test",
    "timestamp": "2026-03-01T00:00:00Z",
    "blocks": {},
}

for block in expected_blocks:
    artifact_dir = meta_dir / f"pipeline-meta-{block}"
    meta_file = artifact_dir / "meta.json"
    if meta_file.exists():
        merged["blocks"][block] = json.loads(meta_file.read_text())
    else:
        merged["blocks"][block] = {"status": "did-not-run"}

out = pathlib.Path("$TMPDIR/pipeline-metadata.json")
out.write_text(json.dumps(merged, indent=2))
print("Merge script completed")
PYEOF

# Assertions
BLOCK_COUNT=$(jq '.blocks | keys | length' "$TMPDIR/pipeline-metadata.json")
CODE_SCAN_SCHEMA=$(jq -r '.blocks["code-scan"].SchemaVersion' "$TMPDIR/pipeline-metadata.json")
BUILD_STATUS=$(jq -r '.blocks["build-artifact"].status' "$TMPDIR/pipeline-metadata.json")
TEST_STATUS=$(jq -r '.blocks["test-artifact"].status' "$TMPDIR/pipeline-metadata.json")

assert_eq "block count"               "8"           "$BLOCK_COUNT"
assert_eq "code-scan schema version"  "2"           "$CODE_SCAN_SCHEMA"
assert_eq "build-artifact status"     "passed"      "$BUILD_STATUS"
assert_eq "test-artifact did-not-run" "did-not-run" "$TEST_STATUS"

if [[ "$ERRORS" -gt 0 ]]; then
  echo "FAILED: $ERRORS assertion(s) failed"; exit 1
else
  echo "ALL PASSED"; exit 0
fi
