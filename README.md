# ansible-tailscale-op-connect-server

Provision Tailscale and 1Password Connect outside Kubernetes—ideal for bootstrapping secure remote access and secrets before a cluster is available (e.g., for Terraform or early automation).

---

## Overview

This project provides an [Ansible](https://ansible.com/) playbook and supporting files to configure a server that runs both [Tailscale](https://tailscale.com/) (for secure overlay networking) and [1Password Connect](https://developer.1password.com/docs/connect/) (for secret management). It is tailored for environments where these services must be available _before_ a Kubernetes cluster is provisioned.

- **Tailscale** is installed and authenticated for secure networking.
- **1Password Connect** is deployed via Docker Compose, reverse-proxied with NGINX, and protected by automatic TLS using Certbot and Cloudflare DNS.
- **All components** are managed by systemd for reliability.

---

## Features

- **Automated host configuration** for 1Password Connect, Tailscale, Docker, Docker Compose, and NGINX.
- **Automated TLS**: Uses Certbot and Cloudflare API tokens for automatic certificate renewal.
- **Secure secret handling**: Credentials and tokens are loaded via environment variables or `secrets.env`.
- **Systemd integration**: 1Password Connect stack is managed as a systemd service.
- **Reproducible development shell**: Provided by Nix flakes for easy onboarding and environment consistency.

---

## Project Structure

```
├── README.md
├── ansible
│   ├── files/
│   │   └── nginx.conf
│   ├── group_vars/
│   │   └── all.yml
│   ├── handlers/
│   │   └── main.yml
│   ├── inventory.ini
│   ├── playbook.yml
│   └── templates/
│       ├── docker-compose.certbot.yml.j2
│       └── docker-compose.yml.j2
├── flake.lock
├── flake.nix
├── requirements.yml
└── secrets.env
```

---

## Nix Flake Environment

This repository provides a [Nix flake](https://nixos.wiki/wiki/Flakes) (`flake.nix`) for a fully reproducible Ansible/Docker development environment.

### Features

- Installs Ansible, git, rsync in a dev shell.
- Sets up Ansible roles/collections locally.
- Loads secrets from `secrets.env` automatically.
- Ensures all Ansible execution is local and reproducible.

**Usage:**
```bash
nix develop
```

---

## Ansible Playbook Details

The main playbook (`ansible/playbook.yml`) configures a host for 1Password Connect and Tailscale:

- **Installs and authenticates Tailscale** using the [artis3n.tailscale.machine](https://galaxy.ansible.com/artis3n/tailscale) role.
- **Installs Docker & Docker Compose** via apt.
- **Adds your user to the docker group**.
- **Writes 1Password credentials** to a file.
- **Copies and renders Docker Compose files** for 1Password Connect and Certbot.
- **Configures NGINX** for reverse proxy.
- **Sets up Certbot** with Cloudflare DNS for automatic TLS certificate renewal.
- **Installs a cron job** for certificate renewal and NGINX reload.
- **Creates a systemd unit** to manage the 1Password Connect stack.
- **Handles all changes with appropriate Ansible handlers.**

### Example: Main Tasks

- Tailscale authentication uses `TAILSCALE_KEY` from environment/`secrets.env`.
- Cloudflare DNS API token (for certbot) is pulled from `CLOUDFLARE_API_TOKEN` in environment/`secrets.env`.
- 1Password Connect credentials are provided as `op_connect_json`.

---

## Getting Started

### 1. Clone & Enter Dev Shell

```bash
git clone https://github.com/JamesAtIntegratnIO/ansible-tailscale-op-connect-server.git
cd ansible-tailscale-op-connect-server
nix develop
```

### 2. Configure Inventory & Secrets

- Edit `ansible/inventory.ini` to list your `1password_host`.
- Fill in variables in `ansible/group_vars/all.yml` and set secrets as environment variables or in `secrets.env`:
    - `TAILSCALE_KEY`
    - `CLOUDFLARE_API_TOKEN`
    - `OP_CONNECT_JSON`
    - `username` (the Linux user to set up and run services as)

### 3. Install Ansible Galaxy Collections

If not using the Nix shell, run:
```bash
ansible-galaxy install -r requirements.yml
```

### 4. Run the Playbook

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

---

## Security Notes

- **Never commit real secrets** to version control.
- Use Ansible Vault or keep `secrets.env` secure.
- Restrict tokens and SSH keys to your intended hosts.

---

## License

[MIT](LICENSE)

---

**Maintainer:** [JamesAtIntegratnIO](https://github.com/JamesAtIntegratnIO)