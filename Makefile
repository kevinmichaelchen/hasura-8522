FLAGS = --skip-update-check --project hasura --admin-secret myadminsecretkey
MIGRATE_FLAGS = --database-name default

.PHONY: start
start:
	docker compose up -d

.PHONY: stop
stop:
	docker compose stop

.PHONY: console
console:
	hasura $(FLAGS) console

.PHONY: migrate
migrate:
	hasura $(FLAGS) $(MIGRATE_FLAGS) \
	  migrate apply

.PHONY: status
status:
	hasura $(FLAGS) $(MIGRATE_FLAGS) \
	  migrate status

.PHONY: md-apply
md-apply:
	hasura $(FLAGS) \
	  metadata apply

.PHONY: md-reload
md-reload:
	hasura $(FLAGS) \
	  metadata reload