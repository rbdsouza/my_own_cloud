# EdgeBox

EdgeBox is an offline-first micro edge platform optimized for Raspberry Pi 4/5 or small x86_64 PCs. It bundles Wi-Fi onboarding, observability, digital signage, a people counter, and secure admin tooling in a single Docker Compose stack designed to run without internet access once container images are seeded.

## Hardware Requirements

- Raspberry Pi 4/5 (4 GB RAM minimum) running Raspberry Pi OS 64-bit **or** a comparable x86_64 mini-PC
- Reliable storage (32 GB microSD or SSD) and USB power supply
- USB camera for the people counter
- HDMI display for signage
- Ethernet uplink (recommended) and/or local Wi-Fi network

## Quick Start

1. Copy `.env.example` to `.env` and customize secrets and locale.
2. On the device, run the installer:
   ```bash
   bash install.sh
   ```
3. Join the fallback SSID `${WIFI_AP_SSID}` (default `EdgeBox-Setup`) and follow the captive portal at `http://192.168.4.1` to connect EdgeBox to the venue Wi-Fi. The access point disables itself once a network is configured.
4. Access local services over mDNS or static DNS overrides:
   - `http://portainer.${LAN_HOST}` — Portainer CE “App Store”
   - `http://sign.${LAN_HOST}` — Digital signage output
   - `http://files.${LAN_HOST}` — File Browser for signage uploads
   - `http://grafana.${LAN_HOST}` — Analytics dashboards
   - `http://counter.${LAN_HOST}/metrics` — People counter metrics
   - `http://api.${LAN_HOST}` — Spring Boot core API
   - `http://auth.${LAN_HOST}` — Authelia login (security profile)

## Docker Compose Profiles

| Profile   | Description |
|-----------|-------------|
| `core`    | Traefik, Portainer, and template server |
| `apps`    | Postgres, Grafana, File Browser, Signage, People Counter, Spring Boot API |
| `wifi`    | Wi-Fi onboarding captive portal |
| `security`| Authelia, CrowdSec, Traefik bouncer, Falco |
| `remote`  | Optional Cloudflare Tunnel (disabled by default) |

Bring the stack online with:
```bash
docker compose --profile core --profile wifi up -d
docker compose --profile apps up -d
```
Enable hardened services when ready:
```bash
docker compose --profile security up -d
```

## Authelia

Authelia protects administration surfaces (Portainer, Grafana, File Browser, Traefik) when the `security` profile is active. The bundled user database uses an Argon2id hash placeholder—generate a new hash before production:
```bash
docker compose exec authelia authelia hash-password 'YourNewPassword'
```
Replace the value in `security/authelia/users_database.yml` and update the `.env` secrets.

## Host Hardening

Run `make secure-host` to execute `hardening/host_hardening.sh`, which configures SSH, Fail2ban, UFW, and basic sysctl hardening. Review and adjust the script for your environment before running.

## Systemd Integration

Install the provided unit to start EdgeBox automatically at boot:
```bash
sudo cp systemd/edgebox-compose.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now edgebox-compose.service
```

## Terraform (Optional)

The `terraform/` directory mirrors the Docker Compose stack using the `kreuzwerker/docker` provider. Use `seed/` scripts to cache images and provider artifacts for offline deployments. Copy `.terraformrc.example` to `~/.terraformrc` to point Terraform at the local mirror.

## Offline Considerations

- Seed container images ahead of time using `make seed-online` and `make seed-offline-load`.
- Configure LAN DNS (router, Pi-hole, AdGuard Home, or `/etc/hosts`) to resolve `*.${LAN_HOST}`.
- The stack functions without internet access once images are cached locally.

## Security Notes

- All non-database services run with read-only filesystems, dropped capabilities, and `no-new-privileges`.
- CrowdSec parses Traefik access logs and blocks abusive clients via the Traefik bouncer.
- Falco monitors the host for suspicious activity.
- Review and rotate all secrets in `.env` and `security/authelia/users_database.yml` before going live.

## License

Released under the MIT License. See [LICENSE](LICENSE).
