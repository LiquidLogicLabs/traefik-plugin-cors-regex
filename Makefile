.PHONY: help test build docker clean release all

# Variables
PLUGIN_NAME := cors-regex
VERSION := $(shell cat VERSION 2>/dev/null || echo "0.1.0")
DOCKER_IMAGE := liquidlogiclabs/traefik-plugin-cors-regex

# Default target
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

test: ## Run tests
	@echo "Running tests..."
	go test ./src/... -v -race -coverprofile=coverage.out
	@echo "Tests completed"

test-coverage: ## Run tests with coverage report
	@echo "Running tests with coverage..."
	go test ./src/... -v -coverprofile=coverage.out
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

build: ## Build the plugin for multiple platforms
	@echo "Building plugin version $(VERSION)..."
	@mkdir -p build
	@platforms="linux/amd64 linux/arm64 darwin/amd64 darwin/arm64"; \
	for platform in $$platforms; do \
		os=$${platform%/*}; \
		arch=$${platform#*/}; \
		output_name="$(PLUGIN_NAME)-$(VERSION)-$$os-$$arch"; \
		echo "Building for $$platform..."; \
		CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch go build \
			-a -installsuffix cgo \
			-ldflags "-X main.version=$(VERSION)" \
			-o "build/$$output_name" \
			./src/; \
	done
	@echo "Build completed"

docker: ## Build Docker image
	@echo "Building Docker image $(DOCKER_IMAGE):$(VERSION)..."
	docker build -t "$(DOCKER_IMAGE):$(VERSION)" -t "$(DOCKER_IMAGE):latest" .
	@echo "Docker build completed"

docker-test: ## Run Docker tests with Traefik and plugin
	@echo "Running Docker tests..."
	@if [ -f "docker/run-tests.sh" ]; then \
		chmod +x docker/run-tests.sh; \
		./docker/run-tests.sh; \
	else \
		echo "Docker test script not found. Running basic Docker Compose test..."; \
		docker compose up -d; \
		sleep 10; \
		docker compose logs traefik; \
		docker compose down; \
	fi
	@echo "Docker tests completed"

docker-clean: ## Clean Docker containers and images
	@echo "Cleaning Docker containers and images..."
	docker compose down -v --remove-orphans
	docker rmi "$(DOCKER_IMAGE):$(VERSION)" "$(DOCKER_IMAGE):latest" 2>/dev/null || true
	@echo "Docker cleanup completed"

docker-push: ## Push Docker image to registry
	@echo "Pushing Docker image..."
	docker push "$(DOCKER_IMAGE):$(VERSION)"
	docker push "$(DOCKER_IMAGE):latest"
	@echo "Docker push completed"

release: ## Create release artifacts
	@echo "Creating release artifacts for version $(VERSION)..."
	@mkdir -p "release/$(VERSION)"
	@if [ -d "build" ]; then \
		cp build/* "release/$(VERSION)/"; \
		cd "release/$(VERSION)"; \
		for file in *; do \
			if [ -f "$$file" ]; then \
				sha256sum "$$file" > "$$file.sha256"; \
			fi; \
		done; \
		echo "Release artifacts created in release/$(VERSION)/"; \
	else \
		echo "No build artifacts found. Run 'make build' first."; \
		exit 1; \
	fi

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf release/
	@rm -f coverage.out coverage.html
	@echo "Clean completed"

deps: ## Download dependencies
	@echo "Downloading dependencies..."
	go mod download
	@echo "Dependencies downloaded"

fmt: ## Format code
	@echo "Formatting code..."
	go fmt ./src/...
	@echo "Code formatting completed"

lint: ## Run linter
	@echo "Running linter..."
	golangci-lint run ./src/...
	@echo "Linting completed"

all: ## Run all steps: test, build, docker, release
	@echo "Running all steps..."
	@$(MAKE) test
	@$(MAKE) build
	@$(MAKE) docker
	@$(MAKE) release
	@echo "All steps completed successfully"

increment-patch: ## Increment patch version
	@echo "Incrementing patch version..."
	@./scripts/build.sh increment patch

increment-minor: ## Increment minor version
	@echo "Incrementing minor version..."
	@./scripts/build.sh increment minor

increment-major: ## Increment major version
	@echo "Incrementing major version..."
	@./scripts/build.sh increment major

dev: ## Development setup
	@echo "Setting up development environment..."
	@$(MAKE) deps
	@$(MAKE) fmt
	@$(MAKE) test
	@echo "Development setup completed"

install-tools: ## Install development tools
	@echo "Installing development tools..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@echo "Development tools installed"
