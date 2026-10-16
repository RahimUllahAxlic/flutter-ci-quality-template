.PHONY: bootstrap get format analyze test coverage check build-web build-apk clean

COVERAGE_THRESHOLD ?= 80

bootstrap:
	./scripts/bootstrap.sh

get:
	flutter pub get

format:
	dart format .

analyze:
	flutter analyze --fatal-infos

test:
	flutter test

coverage:
	flutter test --coverage --file-reporter json:test-results.json
	python3 scripts/ci_report.py --tests test-results.json \
		--lcov coverage/lcov.info --min-coverage $(COVERAGE_THRESHOLD)

# Same gates CI runs. If this passes locally, CI should pass.
check:
	dart format --output=none --set-exit-if-changed .
	flutter analyze --fatal-infos
	$(MAKE) coverage

build-web:
	flutter build web --release

build-apk:
	flutter build apk --release

clean:
	flutter clean
	rm -rf coverage test-results.json
