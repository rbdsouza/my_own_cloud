.PHONY: up up-security up-remote down logs ps secure-host seed-online seed-offline-load scan

up:
	docker compose --profile core --profile wifi up -d
	docker compose --profile apps up -d

up-security:
	docker compose --profile security up -d

up-remote:
	docker compose --profile remote up -d

down:
	docker compose down

logs:
	docker compose logs -f

ps:
	docker compose ps

secure-host:
	sudo bash hardening/host_hardening.sh

seed-online:
	bash terraform/seed/seed_images.sh pull

seed-offline-load:
	bash terraform/seed/seed_images.sh load

scan:
	trivy fs --exit-code 1 --severity HIGH,CRITICAL . || true
	trivy image traefik:v3.1 || true
