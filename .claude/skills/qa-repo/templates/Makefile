SHELL := /bin/bash
include .env
export
name ?= local
db_date ?= $(shell date +%Y-%m-%d-%H-%M)
# Image tag to run; defaults to APP_VERSION from .env.
issue ?= $(APP_VERSION)

start:
	@echo "Start database first"
	APP_VERSION=${issue} docker compose up -d __DB_SERVICE__ rabbit
	@echo "Pulling docker containers..."
	APP_VERSION=${issue} FRONT_APP_VERSION=${front_issue} docker compose pull ${app}
	@echo "Starting docker containers"
	APP_VERSION=${issue} FRONT_APP_VERSION=${front_issue} docker compose up -d ${app} --remove-orphans
run:
	@echo "Starting a shell in the container"
	APP_VERSION=${issue} docker compose run ${app} /bin/sh
restart:
	@echo "Restarting docker containers"
	docker compose restart ${app}
stop:
	@echo "Stopping containers..."
	APP_VERSION=${issue} docker compose stop ${app}
	@echo "Containers stopped"
clean:
	@echo "Stopping docker containers..."
	APP_VERSION=${issue} docker compose stop
	@echo "Removing docker containers"
	APP_VERSION=${issue} docker compose rm
clean_all:
	@echo "Stopping docker containers..."
	APP_VERSION=${issue} docker compose kill
	@echo "Removing docker containers"
	APP_VERSION=${issue} docker compose rm
	@echo "Removing containers, networks and volumes"
	APP_VERSION=${issue} docker compose down -v
logs:
	docker compose logs -f ${app}
reset_db:
	@echo "Loading the database from the init_db folder"
	@echo "If there is no database dump in init_db the database will be empty"
	@echo "Destroying old database..."
	docker compose down -v
	@echo "Creating new database..."
	docker compose up -d __DB_SERVICE__
	@echo "New database from init_db is ready"
backup_db:
	docker compose up -d __DB_SERVICE__
	mkdir -p sql
	@echo Backing up the database into sql/${db_date}-${name}.sql
	__DB_DUMP_CMD__ > sql/${db_date}-${name}.sql
	@echo "Database backed up"
db_shell:
	__DB_SHELL_CMD__
run_scheduler:
	METHOD=${method} SERVICE=${service} APP_VERSION=${issue} docker compose --profile manual run --rm scheduler
full_clean:
	@echo "Stopping docker containers..."
	docker compose stop
	docker system prune -a --volumes
