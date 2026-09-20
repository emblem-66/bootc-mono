#!/usr/bin/env bash
set -xeuo pipefail

FLAVOR="${1:?ERROR: FLAVOR argument is required}"

# ── Parse TOML ────────────────────────────────────────────────────────────────

parse_toml() {
    local section="$1"
    local key="$2"
    python3 - << EOF
import tomllib
with open('/ctx/config.toml', 'rb') as f:
    data = tomllib.load(f)
common = data.get('common', {}).get('$key', [])
flavor = data.get('$section', {}).get('$key', [])
print('\n'.join(common + flavor))
EOF
}

# ── Repos ─────────────────────────────────────────────────────────────────────

#dnf config-manager setopt fedora-cisco-openh264.enabled=0

# ── Remove ────────────────────────────────────────────────────────────────────

mapfile -t remove_packages < <(parse_toml "$FLAVOR" debloat)
[[ ${#remove_packages[@]} -gt 0 ]] && dnf remove -y "${remove_packages[@]}"

dnf autoremove -y

# ── Install ───────────────────────────────────────────────────────────────────

mapfile -t install_packages < <(parse_toml "$FLAVOR" packages)
[[ ${#install_packages[@]} -gt 0 ]] && dnf install -y "${install_packages[@]}"

# ── Systemd ───────────────────────────────────────────────────────────────────

mapfile -t enable_units < <(parse_toml "$FLAVOR" services)
[[ ${#enable_units[@]} -gt 0 ]] && systemctl enable "${enable_units[@]}"

mapfile -t enable_user_units < <(parse_toml "$FLAVOR" user_services)
[[ ${#enable_user_units[@]} -gt 0 ]] && systemctl --global enable "${enable_user_units[@]}"

# ── Tweaks ────────────────────────────────────────────────────────────────────

sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service
sed -i 's|#AutomaticUpdatePolicy.*|AutomaticUpdatePolicy=stage|' /etc/rpm-ostreed.conf
sed -i 's|#LockLayering.*|LockLayering=true|' /etc/rpm-ostreed.conf

echo "%wheel ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-passwordless-sudo
chmod 0440 /etc/sudoers.d/90-passwordless-sudo

# ── Done ──────────────────────────────────────────────────────────────────────
