#!/usr/bin/env bash
# One-time setup: generate the android/ and web/ platform folders, install
# dependencies and normalise formatting. Commit the result.
#
# Usage: scripts/bootstrap.sh [--org com.yourcompany]
set -euo pipefail

cd "$(dirname "$0")/.."

ORG="dev.example"
if [[ "${1:-}" == "--org" && -n "${2:-}" ]]; then
  ORG="$2"
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found. Install it first: https://docs.flutter.dev/get-started/install" >&2
  exit 1
fi

if [[ ! -d android || ! -d web ]]; then
  flutter create . \
    --platforms=android,web \
    --project-name flutter_ci_quality_template \
    --org "$ORG"
  # `flutter create` drops a counter-app smoke test that does not match this app.
  rm -f test/widget_test.dart
fi

flutter pub get
dart format .

echo
echo "Bootstrap complete. Next: make check"
