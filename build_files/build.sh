#!/bin/bash

set -ouex pipefail

BUILD_VARIANT="${BUILD_VARIANT:-bazzite-nvidia-open}"
echo "Building variant: ${BUILD_VARIANT}"

if [ "${BUILD_VARIANT}" = "bazzite-deck" ]; then
    echo "Deck variant: skipping starship, 1password, Visual Studio Code, and programming tools"
else
    # My preferred prompt
    dnf5 -y copr enable atim/starship
    dnf5 -y install starship

    # https://support.1password.com/install-linux/#fedora-or-red-hat-enterprise-linux
    rpm --import https://downloads.1password.com/linux/keys/1password.asc
    echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo
    dnf5 -y install 1password 1password-cli

    # https://code.visualstudio.com/docs/setup/linux#_rhel-fedora-and-centos-based-distributions
    rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo
    dnf5 -y install code

    # Find files fast
    dnf5 -y install plocate
    systemctl enable plocate-updatedb.timer

    # Programming stuff I find handy
    dnf -y install --skip-unavailable ruff uv pre-commit jq yq gh git-lfs git-filter-repo git-koji nodejs nodejs-npm yamllint perltidy perl-CPAN perl-App-cpanminus sqlite sqlite-tools shfmt shellcheck

    # Random other stuff I end up wanting
    dnf -y install --skip-unavailable bzip2 bzip3 bzip3-grep bzip3-grep bzip3-tools unzip xz gzip ncompress p7zip zip netcat mtr
    # Services I like to be sure are set up
    systemctl enable man-db-cache-update.service man-db-restart-cache-update.service chrony-wait.service
fi

# Manage dotfiles
dnf -y install --skip-unavailable chezmoi chezmoi-bash-completion chezmoi-fish-completion

# https://pkgs.tailscale.com/stable/#fedora
dnf5 config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf5 -y install tailscale
systemctl enable tailscaled



# Lightweight editors that aren't vi
dnf -y install --skip-unavailable joe jupp nano

# Track /etc with git
dnf5 -y install etckeeper
systemctl enable etckeeper.timer
