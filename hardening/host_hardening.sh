#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

read -rp "Enter the limited sudo username to create (default: edgeadmin): " USERNAME
USERNAME=${USERNAME:-edgeadmin}

if ! id "${USERNAME}" &>/dev/null; then
  adduser --disabled-password --gecos "EdgeBox Administrator" "${USERNAME}"
  echo "${USERNAME} ALL=(ALL) NOPASSWD: /usr/bin/docker" > "/etc/sudoers.d/${USERNAME}-docker"
fi

echo "Hardening SSH..."
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh || systemctl restart sshd

echo "Installing host security packages..."
apt-get update
apt-get install -y ufw unattended-upgrades auditd apparmor-utils fail2ban

ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

cat <<SYSCTL >/etc/sysctl.d/99-edgebox.conf
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 1
net.ipv4.conf.default.secure_redirects = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
SYSCTL

sysctl --system

cat <<JAIL >/etc/fail2ban/jail.d/edgebox.conf
[sshd]
enabled = true
maxretry = 4
findtime = 1h
bantime = 24h
JAIL

systemctl enable --now fail2ban

cat <<'INSTRUCTIONS'
Host hardening complete. Review the steps above and adjust for your environment.
Remember to configure unattended-upgrades according to your maintenance policy.
INSTRUCTIONS
