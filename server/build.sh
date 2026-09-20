#!/bin/bash
set -euo pipefail

mapfile -t remove-packages < <(grep -hv '^\s*#\|^\s*$' /ctx/packages/debloat)
dnf install -y "${remove-packages[@]}"

mapfile -t install-packages < <(grep -hv '^\s*#\|^\s*$' /ctx/packages/common /ctx/packages/flavour)
dnf install -y "${install-packages[@]}"

