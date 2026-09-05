# Override with a shell-quoted file list to check only changed Swift files.
SWIFT_FILES ?= .

SHELL := /bin/bash

.PHONY: setup format lint test

setup:
	brew bundle install
	mint bootstrap
	lefthook install

format:
	mint run --no-install nicklockwood/SwiftFormat $(SWIFT_FILES) --config .swiftformat --quiet
	mint run --no-install realm/SwiftLint lint --config .swiftlint.yml --fix --quiet --force-exclude $(SWIFT_FILES)

lint: lint-workflows
	mint run --no-install realm/SwiftLint lint --config .swiftlint.yml --quiet --force-exclude $(SWIFT_FILES)

test:
	swift test

.PHONY: lint-workflows

lint-workflows:
	actionlint
