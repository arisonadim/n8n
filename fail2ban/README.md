# fail2ban Configuration for n8n

This directory contains fail2ban configuration files to protect your n8n instance.

## Installation

```bash
# Install fail2ban
sudo apt-get update && sudo apt-get install -y fail2ban

# Copy jail configuration
sudo cp jail.local /etc/fail2ban/jail.local

# Copy n8n filter
sudo cp filter.d/n8n-auth.conf /etc/fail2ban/filter.d/n8n-auth.conf

# Restart fail2ban
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
```

## What's Protected

| Jail | Description | Max Retries | Ban Time |
|------|-------------|-------------|----------|
| sshd | SSH brute force | 3 | 1 hour |
| nginx-http-auth | Nginx basic auth | 5 | 10 min |
| nginx-limit-req | Rate limit violations | 10 | 10 min |
| n8n-auth | n8n login failures | 5 | 30 min |

## Commands

```bash
# Check status
sudo fail2ban-client status

# Check specific jail
sudo fail2ban-client status n8n-auth
sudo fail2ban-client status sshd

# Unban an IP
sudo fail2ban-client set n8n-auth unbanip 1.2.3.4

# Test filter regex
sudo fail2ban-regex /var/lib/docker/containers/*/*.log /etc/fail2ban/filter.d/n8n-auth.conf
```

## Notes

- Docker container logs are in `/var/lib/docker/containers/*/*.log`
- Nginx logs are in `/var/log/nginx/`
- Adjust `bantime`, `findtime`, and `maxretry` as needed
