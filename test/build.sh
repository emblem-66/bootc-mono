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








packages=(
  # Network / Connectivity
  NetworkManager
  NetworkManager-adsl
  NetworkManager-bluetooth
  NetworkManager-config-connectivity-fedora
  NetworkManager-libnm
  NetworkManager-openconnect
  NetworkManager-openvpn
  NetworkManager-strongswan
  NetworkManager-ssh
  NetworkManager-ssh-selinux
  NetworkManager-vpnc
  NetworkManager-wifi
  NetworkManager-wwan
  openconnect
  spoofdpi
  vpnc
  wireguard-tools
  mobile-broadband-provider-info
  ifuse
  jmtpfs
  gvfs-mtp
  gvfs-nfs
  gvfs-smb
  gvfs-archive

  # Printing / CUPS / Drivers
  cups
  cups-pk-helper
  dymo-cups-drivers
  gutenprint-cups
  hplip
  printer-driver-brlaser
  ptouch-driver
  system-config-printer-libs
  system-config-printer-udev

  # Audio / Firmware
  alsa-firmware
  alsa-sof-firmware
  alsa-tools-firmware
  intel-audio-firmware
  atheros-firmware
  brcmfmac-firmware
  iwlegacy-firmware
  iwlwifi-dvm-firmware
  iwlwifi-mvm-firmware
  realtek-firmware
  mt7xxx-firmware
  nxpwireless-firmware
  tiwilink-firmware

  # Security / Authentication
  audispd-plugins
  audit
  fprintd
  fprintd-pam
  pam_yubico
  pcsc-lite
  firewalld

  # Containers
  distrobox
  systemd-container

  # Fonts
  default-fonts
  default-fonts-core-emoji
  glibc-all-langpacks
  google-noto-emoji-fonts
  google-noto-color-emoji-fonts
  nerd-fonts

  # Performance
  cachyos-ksm-settings
  cachyos-settings
  ksmtuned
  scxctl
  scx-manager
  scx-scheds-git
  scx-tools-git
  power-profiles-daemon
  thermald

  # System / Utilities
  fuse
  fuse-common
  fwupd
  inotify-tools
  libcamera
  libcamera-v4l2
  libcamera-gstreamer
  libcamera-tools
  libimobiledevice
  libimobiledevice-utils
  libratbag-ratbagd
  man-db
  man-pages
  plymouth
  plymouth-system-theme
  rsync
  steam-devices
  switcheroo-control
  unzip
  usb_modeswitch
  uxplay
  whois
  xdg-user-dirs
  xdg-terminal-exec

  # Extra
  bazaar
  fastfetch
  firewall-config
  flatpak
  glx-utils
  tailscale
  v4l2loopback
)

dnf5 -y install "${packages[@]}"

# Dependencies for the First Boot Setup
packages=(
  niri
  python3-gobject
  gtk4
  gtk4-layer-shell
  webkitgtk6.0
)

dnf5 -y install "${packages[@]}" --setopt=install_weak_deps=False
mv /usr/share/wayland-sessions/niri.desktop /usr/share/wayland-sessions/niri.desktop.disabled

# First Boot Setup GUI
curl -fsSL https://github.com/Zena-Linux/Zena-Setup/raw/refs/heads/main/zena-setup | install -m 755 /dev/stdin /usr/libexec/zena-setup
curl -fsSL https://github.com/Zena-Linux/Zena-Setup/raw/refs/heads/main/zena-setup-daemon | install -m 755 /dev/stdin /usr/libexec/zena-setup-daemon





system_services=(
  bootc-fetch-apply-updates.service
  podman.socket
  chronyd.service
  firewalld.service
  podman-tcp.service
  zena-setup.service
  systemd-resolved.service
  tailscaled.service
)

user_services=(
  podman.socket
  ssh-agent.service
  gpg-agent.service
  flathub-setup.service
)

mask_services=(
  logrotate.service
  logrotate.timer
  akmods-keygen.target
  rpm-ostree-countme.timer
  rpm-ostree-countme.service
  systemd-remount-fs.service
  flatpak-add-fedora-repos.service
  NetworkManager-wait-online.service
  akmods-keygen@akmods-keygen.service
)

systemctl enable "${system_services[@]}"
systemctl mask "${mask_services[@]}"
systemctl --global enable "${user_services[@]}"

preset_file="/usr/lib/systemd/system-preset/01-zena.preset"
touch "$preset_file"

for service in "${system_services[@]}"; do
    echo "enable $service" >> "$preset_file"
done

mkdir -p "/etc/systemd/user-preset/"
preset_file="/etc/systemd/user-preset/01-zena.preset"
touch "$preset_file"

for service in "${user_services[@]}"; do
    echo "enable $service" >> "$preset_file"
done

systemctl --global preset-all




RELEASE="$(rpm -E %fedora)"
DATE=$(date +%Y%m%d)

sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bootc update --quiet|' /usr/lib/systemd/system/bootc-fetch-apply-updates.service
sed -i 's|#AutomaticUpdatePolicy.*|AutomaticUpdatePolicy=stage|' /etc/rpm-ostreed.conf
sed -i 's|#LockLayering.*|LockLayering=true|' /etc/rpm-ostreed.conf

install -Dpm0644 -t /usr/share/plymouth/themes/spinner/ /ctx/assets/logos/watermark.png

sed -i '/^[[:space:]]*Defaults[[:space:]]\+timestamp_timeout[[:space:]]*=/d;$a Defaults timestamp_timeout=1' /etc/sudoers

curl -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
echo "Default=true" | tee -a /etc/flatpak/remotes.d/flathub.flatpakrepo > /dev/null
flatpak remote-add --if-not-exists --system flathub /etc/flatpak/remotes.d/flathub.flatpakrepo
flatpak remote-modify --system --enable flathub

sed -i -f - /usr/lib/os-release <<EOF
s|^NAME=.*|NAME=\"Zena\"|
s|^ID=.*|ID=\"zena\"|
s|^VERSION=.*|VERSION=\"${RELEASE}.${DATE}\"|
s|^PRETTY_NAME=.*|PRETTY_NAME=\"Zena ${RELEASE}.${DATE}\"|
s|^LOGO=.*|LOGO=\"cachyos\"|
s|^HOME_URL=.*|HOME_URL=\"https://github.com/Zena-Linux/Zena\"|
s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"https://github.com/Zena-Linux/Zena/issues\"|
s|^SUPPORT_URL=.*|SUPPORT_URL=\"https://github.com/Zena-Linux/Zena/issues\"|
s|^CPE_NAME=\".*\"|CPE_NAME=\"cpe:/o:zena-linux:zena\"|
s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"https://github.com/Zena-Linux/Zena\"|
s|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME="zena"|

/^REDHAT_BUGZILLA_PRODUCT=/d
/^REDHAT_BUGZILLA_PRODUCT_VERSION=/d
/^REDHAT_SUPPORT_PRODUCT=/d
/^REDHAT_SUPPORT_PRODUCT_VERSION=/d
EOF







packages=(
  adw-gtk3-theme
  alacritty
  cava
  danksearch
  dgop
  dms
  dms-greeter
  glycin-thumbnailer
  kanshi
  khal
  kf6-kimageformats
  nautilus
  papirus-icon-theme
  quickshell
  xdg-desktop-portal-gtk
  xdg-desktop-portal-gnome
  wl-clipboard
)
dnf5 -y install "${packages[@]}" --exclude=matugen --exclude=noctalia-qs
dnf5 -y install nautilus-python matugen --releasever=44 --disablerepo='*copr*'

packages=(
  gnome-keyring
  gnome-keyring-pam
  mangowc
  pinentry-gnome3
  zenity
)

dnf5 -y install "${packages[@]}" --setopt=install_weak_deps=False

XDG_EXT_TMPDIR="$(mktemp -d)"
curl -fsSLo - "$(curl -fsSL https://api.github.com/repos/tulilirockz/xdg-terminal-exec-nautilus/releases/latest | jq -rc .tarball_url)" | tar -xzvf - -C "${XDG_EXT_TMPDIR}"
install -Dpm0644 -t "/usr/share/nautilus-python/extensions/" "${XDG_EXT_TMPDIR}"/*/xdg-terminal-exec-nautilus.py
rm -rf "${XDG_EXT_TMPDIR}"

dconf update
systemctl set-default graphical.target
mv /usr/share/wayland-sessions/niri.desktop.disabled /usr/share/wayland-sessions/niri.desktop
sed -i 's|^Exec=.*|Exec=bash -c "niri-session > /dev/null 2>\&1"|' \
  /usr/share/wayland-sessions/niri.desktop

sed -i 's|^Exec=.*|Exec=bash -c "mango -s mango-session > /dev/null 2>\&1"|' \
  /usr/share/wayland-sessions/mango.desktop




system_services=(
  greetd.service
  flatpak-theme.service
)

user_services=(
  dms.service
  dms-watch.path
  dsearch.service
  wm-setup.service
  flathub-setup.service
  gnome-keyring-daemon.socket
  gnome-keyring-daemon.service
  dms-greeter-sync-trigger.service
)

systemctl enable "${system_services[@]}"

preset_file="/usr/lib/systemd/system-preset/01-zena.preset"
touch "$preset_file"

for service in "${system_services[@]}"; do
  echo "enable $service" >> "$preset_file"
done

mkdir -p "/etc/systemd/user-preset/"
preset_file="/etc/systemd/user-preset/01-zena.preset"
touch "$preset_file"

for service in "${user_services[@]}"; do
  echo "enable $service" >> "$preset_file"
done

systemctl --global preset-all



























KVER=$(ls /usr/lib/modules | head -n1)

depmod -a "$KVER"
export DRACUT_NO_XATTR=1
/usr/bin/dracut \
  --no-hostonly \
  --kver "$KVER" \
  --reproducible \
  --zstd -v \
  --add ostree --add fido2 \
  -f "/usr/lib/modules/$KVER/initramfs.img"

chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"
