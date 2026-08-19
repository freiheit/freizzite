#!/bin/bash
set -ouex pipefail

# shellcheck source=/dev/null
source /ctx/lib-verify.sh

# Common packages for all variants
# Verified installed after the transaction; a missing one fails the build.
COMMON_PACKAGES=(
    age
    bitstream-vera-fonts-all
    chezmoi
    etckeeper
    firacode-nerd-fonts
    firamono-nerd-fonts
    google-android-emoji-fonts
    google-roboto-fonts
    htop
    joe
    jupp
    keychain
    ms-core-tahoma-fonts
    ms-core-verdana-fonts
    nano
    powertop
    tailscale
)

# Installed the same way but not verified: nice to have, not worth a red
# build when terra lags a Fedora bump.
COMMON_PACKAGES_OPTIONAL=(
    bitstreamverasansmono-nerd-fonts
    chezmoi-bash-completion
    chezmoi-fish-completion
    droidsansmono-nerd-fonts
    noto-nerd-fonts
    robotomono-nerd-fonts
    ubuntu-nerd-fonts
    ubuntumono-nerd-fonts
    ubuntusans-nerd-fonts
)

# Common services for all variants
COMMON_SYSTEMCTL=(
    etckeeper.timer
    tailscaled.service
)

# Enable tailscale repo
dnf5 config-manager setopt tailscale-stable.enabled=true

dnf5 -y install --skip-unavailable --skip-broken --enable-repo=terra \
    "${COMMON_PACKAGES[@]}" "${COMMON_PACKAGES_OPTIONAL[@]}"

systemctl enable "${COMMON_SYSTEMCTL[@]}"

tailscale completion fish > /etc/fish/completions/tailscale.fish
tailscale completion bash > /etc/bash_completion.d/tailscale

# Fail the build if any requested package didn't actually get installed
verify_packages_installed "${COMMON_PACKAGES[@]}"
