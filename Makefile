.DEFAULT_GOAL := help

.PHONY: deploy update help

deploy: ## Deploy latest changes to cartman
	bin/deploy.sh

update: ## Pull latest Docker images and restart updated containers on cartman
	bin/update.sh

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
