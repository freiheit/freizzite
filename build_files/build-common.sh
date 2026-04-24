#!/bin/bash
set -ouex pipefail

# Common packages for all variants
COMMON_PACKAGES=(
    chezmoi
    chezmoi-bash-completion
    chezmoi-fish-completion
    tailscale
    joe
    jupp
    nano
    etckeeper
)

# Common services for all variants
COMMON_SYSTEMCTL=(
    tailscaled.service
    etckeeper.timer
)

# Enable tailscale repo
dnf5 config-manager setopt tailscale-stable.enabled=true

dnf5 -y install --skip-unavailable --enable-repo=terra "${COMMON_PACKAGES[@]}"

systemctl enable "${COMMON_SYSTEMCTL[@]}"
