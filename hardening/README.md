# EdgeBox Host Hardening

The scripts and configuration snippets in this directory help secure the Docker host that runs EdgeBox.

- `host_hardening.sh`: Automates common tasks such as creating a dedicated admin user, hardening SSH, enabling `ufw`, and configuring Fail2ban.
- `docker_daemon.json`: Example daemon configuration enabling user namespace remapping, stricter logging, and ulimit tuning. Copy this file to `/etc/docker/daemon.json` and restart Docker.

Review every change before applying it to production. The script assumes a Debian-based host (Raspberry Pi OS 64-bit or Ubuntu).
