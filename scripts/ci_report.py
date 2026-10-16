#!/usr/bin/env python3
"""Summarise Flutter test + coverage output and enforce a coverage gate.

Inputs
  --tests  JSON event stream from `flutter test --file-reporter json:<path>`
  --lcov   lcov file from `flutter test --coverage`

Output
  A Markdown report, appended to $GITHUB_STEP_SUMMARY when set (or --summary),
  otherwise printed to stdout.

Exit status
  0  all tests passed and coverage >= --min-coverage
  1  a test failed, or coverage is below the threshold (or missing while a
     threshold is set)

Only the standard library is used, so this runs on any CI runner as-is.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class TestReport:
    passed: int = 0
    failed: int = 0
    skipped: int = 0
    duration_ms: int = 0
    failures: list[tuple[str, str]] = field(default_factory=list)

    @property
    def total(self) -> int:
        return self.passed + self.failed + self.skipped


@dataclass
class Coverage:
    per_file: dict[str, tuple[int, int]]  # path -> (lines found, lines hit)

    @property
    def found(self) -> int:
        return sum(found for found, _ in self.per_file.values())

    @property
    def hit(self) -> int:
        return sum(hit for _, hit in self.per_file.values())

    @property
    def percent(self) -> float:
        return 100.0 * self.hit / self.found if self.found else 0.0


def parse_tests(path: Path) -> TestReport:
    names: dict[int, str] = {}
    errors: dict[int, str] = {}
    report = TestReport()

    for raw in path.read_text(encoding="utf-8").splitlines():
        raw = raw.strip()
        if not raw.startswith("{"):
            continue
        try:
            event = json.loads(raw)
        except json.JSONDecodeError:
            continue

        kind = event.get("type")
        if kind == "testStart":
            test = event["test"]
            names[test["id"]] = test.get("name", "")
        elif kind == "error":
            errors.setdefault(event["testID"], str(event.get("error", "")).strip())
        elif kind == "testDone":
            result = event.get("result")
            # Hidden entries are synthetic ("loading <file>"); ignore them
            # unless they failed, which means a file could not even load.
            if event.get("hidden") and result == "success":
                continue
            test_id = event["testID"]
            if event.get("skipped"):
                report.skipped += 1
            elif result == "success":
                report.passed += 1
            else:
                report.failed += 1
                report.failures.append(
                    (names.get(test_id, f"test #{test_id}"), errors.get(test_id, ""))
                )
        elif kind == "done":
            report.duration_ms = int(event.get("time", 0))

    return report


def parse_lcov(path: Path) -> Coverage:
    per_file: dict[str, list[int]] = {}
    current: str | None = None

    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("SF:"):
            current = line[3:]
            per_file[current] = [0, 0]
        elif current and line.startswith("LF:"):
            per_file[current][0] = int(line[3:])
        elif current and line.startswith("LH:"):
            per_file[current][1] = int(line[3:])
        elif line == "end_of_record":
            current = None

    return Coverage({name: (found, hit) for name, (found, hit) in per_file.items()})


def render(tests: TestReport | None, cov: Coverage | None, minimum: float) -> str:
    out: list[str] = []

    if tests is not None:
        status = "✅" if tests.failed == 0 else "❌"
        out += [
            f"## {status} Test results",
            "",
            "| Passed | Failed | Skipped | Total | Duration |",
            "| ---: | ---: | ---: | ---: | ---: |",
            f"| {tests.passed} | {tests.failed} | {tests.skipped} "
            f"| {tests.total} | {tests.duration_ms / 1000:.1f}s |",
            "",
        ]
        if tests.failures:
            out.append("### Failures")
            out.append("")
            for name, error in tests.failures:
                out.append(f"- **{name}**")
                if error:
                    first_line = error.splitlines()[0]
                    out.append(f"  - `{first_line}`")
            out.append("")

    if cov is not None:
        ok = cov.percent >= minimum
        out += [
            f"## {'✅' if ok else '❌'} Coverage",
            "",
            f"**{cov.percent:.1f}%** of lines ({cov.hit}/{cov.found}) "
            f"· threshold {minimum:.0f}%",
            "",
            "<details><summary>Per-file coverage (lowest first)</summary>",
            "",
            "| File | Lines | Coverage |",
            "| --- | ---: | ---: |",
        ]
        rows = sorted(
            cov.per_file.items(),
            key=lambda item: (item[1][1] / item[1][0]) if item[1][0] else 1.0,
        )
        for name, (found, hit) in rows:
            pct = 100.0 * hit / found if found else 100.0
            out.append(f"| `{name}` | {hit}/{found} | {pct:.0f}% |")
        out += ["", "</details>", ""]

    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--tests", type=Path, help="JSON test results file")
    parser.add_argument("--lcov", type=Path, help="lcov coverage file")
    parser.add_argument("--min-coverage", type=float, default=0.0)
    parser.add_argument(
        "--summary",
        type=Path,
        default=os.environ.get("GITHUB_STEP_SUMMARY"),
        help="file to append the Markdown report to (default: $GITHUB_STEP_SUMMARY)",
    )
    args = parser.parse_args()

    failed = False
    tests = cov = None

    if args.tests:
        if args.tests.is_file():
            tests = parse_tests(args.tests)
            failed |= tests.failed > 0
        else:
            print(f"::warning::test results not found: {args.tests}")
            failed = True

    if args.lcov:
        if args.lcov.is_file():
            cov = parse_lcov(args.lcov)
            if cov.percent < args.min_coverage:
                print(
                    f"::error::Coverage {cov.percent:.1f}% is below the "
                    f"{args.min_coverage:.0f}% threshold"
                )
                failed = True
        else:
            print(f"::warning::coverage file not found: {args.lcov}")
            failed |= args.min_coverage > 0

    report = render(tests, cov, args.min_coverage)
    if args.summary:
        with open(args.summary, "a", encoding="utf-8") as handle:
            handle.write(report + "\n")
    else:
        print(report)

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
