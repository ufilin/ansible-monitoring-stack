.PHONY: up down logs lint

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=100

lint:
	yamllint .
	ansible-lint ansible/playbook.yml
	docker compose config -q
