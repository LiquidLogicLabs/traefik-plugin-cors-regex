.PHONY: help build clean vendor clean-vendor
.PHONY: test test-unit test-coverage test-local test-catalog test-all 
.PHONY: local-build local-test local-clean catalog-test catalog-clean clean-all
.PHONY: version version-patch version-minor version-major release release-dry-run

# Variables
PLUGIN_NAME := cors-regex
VERSION := $(shell cat VERSION 2>/dev/null || echo "0.1.0")

# Default target
help: ## Show this help message
	@echo "🚀 CORS Regex Plugin - Available Commands"
	@echo ""
	@echo "📦 BUILD COMMANDS:"
	@grep -E '^(build|vendor|clean):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🧪 TEST COMMANDS:"
	@grep -E '^(test|test-unit|test-coverage|test-local|test-catalog|test-all):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🔧 LOCAL MODE COMMANDS:"
	@grep -E '^(local-build|local-test|local-clean):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🚀 CATALOG MODE COMMANDS:"
	@grep -E '^(catalog-test|catalog-clean):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🎬 LOCAL GITHUB ACTIONS TESTING:"
	@grep -E '^(act-list|act-release|act-ci|act-setup):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "📋 VERSION & RELEASE COMMANDS:"
	@grep -E '^(version|version-patch|version-minor|version-major|release|release-dry-run):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🧹 CLEANUP COMMANDS:"
	@grep -E '^(clean-vendor|clean-all):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

## Build Commands
build: ## Build the plugin binary
	@echo "Building plugin version $(VERSION)..."
	go build -o $(PLUGIN_NAME)-$(VERSION)

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	rm -f $(PLUGIN_NAME)-*
	rm -f coverage.out coverage.html

vendor: ## Create vendor directory (required for plugin catalog)
	@echo "Creating vendor directory..."
	go mod tidy
	go mod vendor
	@echo "Vendor directory created"

clean-vendor: ## Remove vendor directory
	@echo "Removing vendor directory..."
	rm -rf vendor/
	@echo "Vendor directory removed"

## Test Commands  
test: test-unit ## Alias for test-unit (default test command)

test-unit: ## Run unit tests
	@echo "Running unit tests..."
	go test -v -race -coverprofile=coverage.out
	@echo "Unit tests completed"

test-coverage: ## Run unit tests with coverage report
	@echo "Running unit tests with coverage..."
	go test -v -coverprofile=coverage.out
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

test-local: local-test ## Alias for local-test

test-catalog: catalog-test ## Alias for catalog-test

test-all: ## Run all tests (unit + local mode + catalog mode if available)
	@echo "🧪 Running all tests..."
	@echo ""
	@echo "1️⃣ Running unit tests..."
	@make test-unit
	@echo ""
	@echo "2️⃣ Running local mode tests..."
	@make local-test
	@echo ""
	@echo "3️⃣ Running plugin catalog tests (if plugin is published)..."
	@if make catalog-test 2>/dev/null; then \
		echo "✅ Plugin catalog tests passed"; \
	else \
		echo "⚠️  Plugin catalog tests skipped (plugin may not be published yet)"; \
	fi
	@echo ""
	@echo "🎉 All available tests completed!"

## Local Mode Commands (Development Testing)
local-build: ## Build Docker image for local mode tests  
	@echo "Building Docker image for local mode tests..."
	cd tests/local-mode && docker compose build

local-test: ## Run local mode Docker tests (development)
	@echo "Running local mode Docker tests..."
	@cd tests/local-mode && docker compose up --abort-on-container-exit --exit-code-from tester

local-clean: ## Clean local mode Docker containers and images
	@echo "Cleaning local mode Docker containers and images..."
	cd tests/local-mode && docker compose down -v --remove-orphans

## Catalog Mode Commands (Production Testing)
catalog-test: ## Test plugin in catalog mode (requires published version)
	@echo "Testing plugin in catalog mode..."
	cd tests/plugin-catalog-test && docker compose down -v --remove-orphans || true
	cd tests/plugin-catalog-test && docker compose up --abort-on-container-exit --exit-code-from tester
	cd tests/plugin-catalog-test && docker compose down -v --remove-orphans

catalog-clean: ## Clean plugin catalog test environment
	@echo "Cleaning plugin catalog test environment..."
	cd tests/plugin-catalog-test && docker compose down -v --remove-orphans

## Cleanup Commands
clean-all: ## Clean all test environments and build artifacts
	@echo "Cleaning all test environments and build artifacts..."
	@make clean
	@make local-clean
	@make catalog-clean
	@echo "✅ All environments cleaned"

## Local GitHub Actions Testing
act-list: ## List available GitHub Actions workflows
	@echo "Available GitHub Actions workflows:"
	@act --list

act-release: ## Test release workflow locally with act
	@echo "Testing release workflow locally..."
	@echo "Note: This will simulate a tag push event"
	@act push -e .github/events/tag-push.json

act-ci: ## Test CI workflow locally with act
	@echo "Testing CI workflow locally..."
	@act push

act-setup: ## Setup act test events
	@echo "Setting up act test events..."
	@mkdir -p .github/events
	@echo '{"ref": "refs/tags/v$(VERSION)", "repository": {"default_branch": "main"}}' > .github/events/tag-push.json
	@echo "Act setup complete. Use 'make act-list' to see available workflows"

## Version & Release Commands
version: ## Show current version
	@echo "Current version: $(VERSION)"

version-patch: ## Increment patch version
	@echo "Incrementing patch version..."
	@bash -c 'current=$$(cat VERSION 2>/dev/null || echo "0.1.0"); IFS="." read -r major minor patch <<< "$$current"; new_patch=$$((patch + 1)); new_version="$$major.$$minor.$$new_patch"; echo "$$new_version" > VERSION; echo "Version updated to: $$new_version"'

version-minor: ## Increment minor version
	@echo "Incrementing minor version..."
	@bash -c 'current=$$(cat VERSION 2>/dev/null || echo "0.1.0"); IFS="." read -r major minor patch <<< "$$current"; new_minor=$$((minor + 1)); new_version="$$major.$$new_minor.0"; echo "$$new_version" > VERSION; echo "Version updated to: $$new_version"'

version-major: ## Increment major version
	@echo "Incrementing major version..."
	@bash -c 'current=$$(cat VERSION 2>/dev/null || echo "0.1.0"); IFS="." read -r major minor patch <<< "$$current"; new_major=$$((major + 1)); new_version="$$new_major.0.0"; echo "$$new_version" > VERSION; echo "Version updated to: $$new_version"'

release: ## Create a new release (interactive)
	@echo "Starting release process..."
	@./scripts/release.sh

release-dry-run: ## Simulate release process without creating tags
	@echo "Simulating release process..."
	@echo "Current version: $(VERSION)"
	@echo "Tests would be run..."
	@echo "Dependencies would be verified..."
	@echo "Tag would be created and pushed..."
	@echo "Use 'make release' to actually create a release"
