#!/usr/bin/env bash
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
SRC="${SRC:-/mayhem}"
cd "$SRC"

emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

if [ ! -x /mayhem/cbor-java-tests ]; then
  echo "FATAL: /mayhem/cbor-java-tests missing" >&2
  emit_ctrf "maven-surefire" 0 1 0
  exit 2
fi

echo "=== running Maven Surefire via /mayhem/cbor-java-tests ==="
out="$(/mayhem/cbor-java-tests 2>&1)"; rc=$?
echo "$out"

line="$(printf '%s\n' "$out" | sed -n 's/^RUNTESTS //p' | head -1)"
if [ -z "$line" ]; then
  line="$(printf '%s\n' "$out" | sed -n 's/.*Tests run: \([0-9][0-9]*\), Failures: \([0-9][0-9]*\), Errors: \([0-9][0-9]*\), Skipped: \([0-9][0-9]*\).*/RUNTESTS tests=\1 passed=\1 failed=\2 errors=\3 skipped=\4/p' | tail -1)"
fi

if [ -z "$line" ]; then
  echo "no RUNTESTS / Surefire summary (rc=$rc)" >&2
  emit_ctrf "maven-surefire" 0 1 0
  exit 1
fi

TESTS=$(echo "$line"   | sed -n 's/.*tests=\([0-9][0-9]*\).*/\1/p')
PASSED=$(echo "$line"  | sed -n 's/.*passed=\([0-9][0-9]*\).*/\1/p')
FAILED=$(echo "$line"  | sed -n 's/.*failed=\([0-9][0-9]*\).*/\1/p')
ERRORS=$(echo "$line"  | sed -n 's/.*errors=\([0-9][0-9]*\).*/\1/p')
SKIPPED=$(echo "$line" | sed -n 's/.*skipped=\([0-9][0-9]*\).*/\1/p')
: "${TESTS:=0}" "${PASSED:=0}" "${FAILED:=0}" "${ERRORS:=0}" "${SKIPPED:=0}"
FAILED=$(( FAILED + ERRORS ))
PASSED=$(( TESTS - FAILED - SKIPPED ))

if [ "$TESTS" -eq 0 ]; then
  emit_ctrf "maven-surefire" 0 1 0
  exit 1
fi

emit_ctrf "maven-surefire" "$PASSED" "$FAILED" "$SKIPPED"
