-include .env
export CLICKHOUSE_HTTP_PORT ?= 8123
export CLICKHOUSE_NATIVE_PORT ?= 9000
export CLICKHOUSE_HOST ?= localhost

PYTHON ?= python3
VENV := .venv
BIN := $(VENV)/bin
DBT := $(BIN)/dbt --no-use-colors
DBT_FLAGS := --profiles-dir .
DOCS_PORT ?= 8080

.PHONY: help venv up load down deps seed run test unit build lint fix docs serve all pre-commit clean

help:
	@echo "make venv      - venv с dbt-core, dbt-clickhouse, sqlfluff, pre-commit"
	@echo "make up        - ClickHouse и загрузка train.csv в transactions_db.transactions"
	@echo "make all       - deps, seed, run, test"
	@echo "make unit      - только unit tests"
	@echo "make lint      - sqlfluff lint"
	@echo "make docs      - dbt docs generate"
	@echo "make serve     - dbt docs serve на порту DOCS_PORT"
	@echo "make down      - остановить ClickHouse"

venv:
	$(PYTHON) -m venv $(VENV)
	$(BIN)/pip install -q -r requirements.txt
	$(BIN)/pre-commit install

up:
	docker compose up -d
	docker compose logs clickhouse-load

down:
	docker compose down

deps:
	$(DBT) deps $(DBT_FLAGS)

seed:
	$(DBT) seed $(DBT_FLAGS)

run:
	$(DBT) run $(DBT_FLAGS)

test:
	$(DBT) test $(DBT_FLAGS)

unit:
	$(DBT) test $(DBT_FLAGS) --select "test_type:unit"

build:
	$(DBT) build $(DBT_FLAGS)

all: deps seed run test

lint:
	$(BIN)/sqlfluff lint models tests

fix:
	$(BIN)/sqlfluff fix models tests

docs:
	$(DBT) docs generate $(DBT_FLAGS)

serve: docs
	$(DBT) docs serve $(DBT_FLAGS) --port $(DOCS_PORT)

pre-commit:
	$(BIN)/pre-commit run --all-files

clean:
	$(DBT) clean $(DBT_FLAGS)
