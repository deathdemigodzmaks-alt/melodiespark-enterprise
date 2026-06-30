.PHONY: help install dev build test lint format clean deploy

help:
	@echo "Available commands:"
	@echo "  make install   - Install dependencies"
	@echo "  make dev       - Start development servers"
	@echo "  make build     - Build for production"
	@echo "  make test      - Run tests"
	@echo "  make lint      - Run linter"
	@echo "  make format    - Format code"
	@echo "  make clean     - Clean build artifacts"
	@echo "  make deploy    - Deploy to production"

install:
	pnpm install

dev:
	pnpm dev

build:
	pnpm build

test:
	pnpm test

lint:
	pnpm lint

format:
	pnpm format

clean:
	pnpm clean
	rm -rf node_modules

deploy:
	bash .saas-deployment/scripts/deploy-cloud.sh
