#!/bin/bash
set -euo pipefail

rpm -qa --qf '%{NAME}.%{ARCH}\n' | sort

rpm -qa --qf '%{NAME}.%{ARCH}\n' | sort > /packagelist_start.txt 2>/dev/null
{ rpm -qa --qf '%{NAME}.%{ARCH}\n' | sort > /packagelist_start.txt; } 2>/dev/null

# ── Repos ────────────────────────────────────────────────────────────────────

dnf config-manager setopt fedora-cisco-openh264.enabled=0

# ── Packages ──────────────────────────────────────────────────────────────────

remove_packages=()
mapfile -t remove_packages < <(grep -hv '^\s*#\|^\s*$' /ctx/packages/common/debloat)
[[ ${#remove_packages[@]} -gt 0 ]] && dnf remove -y "${remove_packages[@]}"

install_packages=()
mapfile -t install_packages < <(grep -hv '^\s*#\|^\s*$' /ctx/packages/common/packages /ctx/packages/specific/packages)
[[ ${#install_packages[@]} -gt 0 ]] && dnf install -y "${install_packages[@]}"

# ── Systemd ───────────────────────────────────────────────────────────────────

disable_units=()
mapfile -t disable_units < <(grep -hv '^\s*#\|^\s*$' /ctx/packages/common/services /ctx/packages/specific/services)
[[ ${#disable_units[@]} -gt 0 ]] && systemctl disable "${disable_units[@]}"

enable_units=()
mapfile -t enable_units < <(grep -hv '^\s*#\|^\s*$' /ctx/packages/common/services /ctx/packages/specific/services)
[[ ${#enable_units[@]} -gt 0 ]] && systemctl enable "${enable_units[@]}"

enable_user_units=()
mapfile -t enable_user_units < <(grep -hv '^\s*#\|^\s*$' /ctx/packages/common/user-services /ctx/packages/specific/user-services)
[[ ${#enable_user_units[@]} -gt 0 ]] && systemctl --global enable "${enable_user_units[@]}"

addwants_graphical_units=()
mapfile -t addwants_graphical_units < <(grep -hv '^\s*#\|^\s*$' /ctx/packages/common/addwants-graphical-units /ctx/packages/specific/addwants-graphical-units)
[[ ${#addwants_graphical_units[@]} -gt 0 ]] && systemctl --global add-wants graphical-session.target "${addwants_graphical_units[@]}"

# ── Tweaks ────────────────────────────────────────────────────────────────────

# Update policies
sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service
sed -i 's|#AutomaticUpdatePolicy.*|AutomaticUpdatePolicy=stage|' /etc/rpm-ostreed.conf

# Disable layering
sed -i 's|#LockLayering.*|LockLayering=true|' /etc/rpm-ostreed.conf

# Passwordless sudo
echo "%wheel ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-passwordless-sudo
chmod 0440 /etc/sudoers.d/90-passwordless-sudo

# ── Done ──────────────────────────────────────────────────────────────────────

rpm -qa --qf '%{NAME}.%{ARCH}\n' | sort > /packagelist_end.txt 2>/dev/null

echo ""
echo "# Removed packages"
comm -23 /packagelist_start.txt /packagelist_end.txt || true

echo ""
echo "# Added packages"
comm -13 /packagelist_start.txt /packagelist_end.txt || true
