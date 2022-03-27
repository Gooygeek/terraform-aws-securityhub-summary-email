
COMPOSE_RUN_TF = docker-compose run terraform
COMPOSE_TF_LINT = docker-compose run terraform-lint
COMPOSE_TF_DOCS = docker-compose run terraform-docs

.env: ## Create .env file
	@echo "No .env file found. Create new .env using .env.template"
	cp .env.template .env

.PHONY: init
init: .env
	$(COMPOSE_RUN_TF) terraform init

.PHONY: #validate
validate: .env init
	$(COMPOSE_RUN_TF) terraform validate

.PHONY: format
format: .env #init
	$(COMPOSE_RUN_TF) terraform fmt

.PHONY: lint
lint: .env #init
	$(COMPOSE_TF_LINT) --init
	$(COMPOSE_TF_LINT) --version
	$(COMPOSE_TF_LINT) --format compact

.PHONY: docs
docs: .env init
	$(COMPOSE_TF_DOCS) markdown --output-file README.md --output-mode inject .

.PHONY: precommit
precommit: .env init validate format lint docs
	echo "Done"

.PHONY: clean
clean:
	rm -rf .env .terraform *.tfstate .tflint.d
