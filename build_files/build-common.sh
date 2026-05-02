#!/bin/bash
set -ouex pipefail

# Common packages for all variants
COMMON_PACKAGES=(
    chezmoi
    chezmoi-bash-completion
    chezmoi-fish-completion
    easyeffects
    etckeeper
    firacode-nerd-fonts
    firamono-nerd-fonts.noarch
    htop
    joe
    jupp
    nano
    powertop
    tailscale
    wiremix
)

# Common services for all variants
COMMON_SYSTEMCTL=(
    etckeeper.timer
    tailscaled.service
)

# Enable tailscale repo
dnf5 config-manager setopt tailscale-stable.enabled=true

dnf5 -y install --skip-unavailable --skip-broken --enable-repo=terra "${COMMON_PACKAGES[@]}"

systemctl enable "${COMMON_SYSTEMCTL[@]}"

tailscale completion fish > /etc/fish/completions/tailscale
tailscale completion bash > /etc/bash_completion.d/tailscale
