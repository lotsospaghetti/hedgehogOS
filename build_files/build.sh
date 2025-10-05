#!/bin/bash

set -ouex pipefail

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# install packages
dnf5 -y install awesfx fluid-soundfont-gm fluid-soundfont-gs
dnf5 -y copr enable julicen/atkinson-hyperlegible-fonts
dnf5 -y install atkinson-hyperlegible-mono-fonts atkinson-hyperlegible-next-fonts
dnf5 -y copr disable julicen/atkinson-hyperlegible-fonts

# enable services
systemctl enable podman.socket
systemctl enable tailscaled.service
systemctl enable virtqemud.service
systemctl enable waydroid-container.service

# import just recipes
echo "import \"/usr/share/hedgehogos/just/hedgehog.just\"" >>/usr/share/ublue-os/justfile
