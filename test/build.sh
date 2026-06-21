#!/usr/bin/env bash
set -xeuo pipefail
shopt -s nullglob

mkdir -p /var/roothome
dnf5 -y install dnf5-plugins
echo -n "max_parallel_downloads=10" >>/etc/dnf/dnf.conf

dnf5 -y install \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

dnf5 -y install --nogpgcheck --repofrompath \
  'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras,-mesa}

dnf5 config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo

coprs=(
  bieszczaders/kernel-cachyos-lto
  bieszczaders/kernel-cachyos-addons

  ublue-os/packages

  yalter/niri
  ulysg/xwayland-satellite
  avengemedia/danklinux
  avengemedia/dms

  che/nerd-fonts
)

for copr in "${coprs[@]}"; do
    echo "Enabling copr: $copr"
    dnf5 -y copr enable "$copr"
done

echo "priority=1" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri.repo
echo "priority=2" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:ulysg:xwayland-satellite.repo
echo "priority=3" | tee -a /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:avengemedia:danklinux.repo
dnf5 -y config-manager setopt "*terra*".priority=3 "*terra*".exclude="nerd-fonts topgrade *scx-* steam python3-protobuf zlib-devel" && \
dnf5 -y config-manager setopt "terra-mesa".enabled=true
dnf5 -y config-manager setopt "*rpmfusion*".priority=5 "*rpmfusion*".exclude="mesa-*"
dnf5 -y config-manager setopt "*fedora*".exclude="mesa-* kernel-core-* kernel-modules-* kernel-uki-virt-*"






packages=(
  kernel-cachyos-lto
  kernel-cachyos-lto-core
  kernel-cachyos-lto-devel-matched
  kernel-cachyos-lto-modules
)

pushd /usr/lib/kernel/install.d
printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install
printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install
chmod +x  05-rpmostree.install 50-dracut.install
popd

for pkg in kernel kernel-core kernel-modules kernel-modules-core; do
    rpm --erase $pkg --nodeps
done

rm -rf "/usr/lib/modules/$(ls /usr/lib/modules | head -n1)"

dnf5 -y install "${packages[@]}"
dnf5 versionlock add "${packages[@]}"

rm -rf /boot/*




# Install the cachyos kernel
#dnf copr enable -y bieszczaders/kernel-cachyos-lto
#dnf copr enable -y bieszczaders/kernel-cachyos-addons
#dnf install -y kernel-cachyos-lto kernel-cachyos-lto-devel-matched
#setsebool -P domain_kernel_load_modules on

# Enable CachyOS kernel repo (LTO/Clang build)
#dnf copr enable -y bieszczaders/kernel-cachyos-lto

# Enable CachyOS addons repo (ananicy-cpp, scx-scheds, cachyos-settings)
#dnf copr enable -y bieszczaders/kernel-cachyos-addons

# Install CachyOS LTO kernel + matched headers/devel
#dnf install -y kernel-cachyos-lto kernel-cachyos-lto-devel-matched

# Remove stock Fedora kernel
#dnf remove -y kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra || true

# Install ananicy-cpp + cachyos rules, and scx scheduler tools
#dnf install -y  ananicy-cpp cachyos-ananicy-rules scx-scheds scx-manager

# Swap default zram-generator config for cachyos-settings (gaming-tuned sysctls, udev rules)
#dnf swap -y  swap zram-generator-defaults cachyos-settings

# Enable ananicy-cpp service
#systemctl enable ananicy-cpp.service

# SELinux: allow CachyOS kernel to load modules
#setsebool -P domain_kernel_load_modules on

# Rebuild initramfs for the new kernel at the path bootc expects
#KVER=$(rpm -q --qf '%{version}-%{release}.%{arch}\n' kernel-cachyos-lto | head -1)
#dracut --force --kver "$KVER" "/usr/lib/modules/${KVER}/initramfs.img"

#dnf install -y \
#    scx-scheds \
#    scx-manager \
#    scx-tools \
#    scxctl \
#    ananicy-cpp \
#    cachyos-ananicy-rules \

#systemctl enable ananicy-cpp






#KVER=$(ls /usr/lib/modules | head -n1)

#depmod -a "$KVER"
#export DRACUT_NO_XATTR=1
#/usr/bin/dracut \
#  --no-hostonly \
#  --kver "$KVER" \
#  --reproducible \
#  --zstd -v \
#  --add ostree --add fido2 \
#  -f "/usr/lib/modules/$KVER/initramfs.img"

#chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"
