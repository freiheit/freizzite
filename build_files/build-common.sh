#!/bin/bash
set -ouex pipefail

# Common packages for all variants
COMMON_PACKAGES=(
    bitstream-vera-fonts-all
    bitstreamverasansmono-nerd-fonts
    chezmoi
    chezmoi-bash-completion
    chezmoi-fish-completion
    droidsansmono-nerd-fonts
    easyeffects
    etckeeper
    firacode-nerd-fonts
    firamono-nerd-fonts
    htop
    joe
    jupp
    ms-core-verdana-fonts
    nano
    noto-nerd-fonts
    powertop
    tailscale
    ubuntu-nerd-fonts
    ubuntumono-nerd-fonts
    ubuntusans-nerd-fonts
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
