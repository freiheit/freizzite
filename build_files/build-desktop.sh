#!/bin/bash
set -ouex pipefail

# Desktop variants:
# Includes: chezmoi, starship, 1password, VSCode, and programming tools

dnf5 -y copr enable atim/starship

# https://code.visualstudio.com/docs/setup/linux#_rhel-fedora-and-centos-based-distributions
rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo

DESKTOP_PACKAGES=(
    # 1Password (Integrations struggle in Flatpak install)
    1password
    1password-cli

    # Fave prompt
    starship

    # Programming stuff I find handy
    code
    gh
    git-filter-repo
    git-koji
    git-lfs
    jq
    nodejs
    nodejs-npm
    perl-App-cpanminus
    perl-CPAN
    perltidy
    pre-commit
    ruff
    ShellCheck
    shfmt
    sqlite
    sqlite-tools
    uv
    yamllint
    yq

    # Handy tools
    plocate
    mtr
    netcat

    # Various (de)compression tools
    bzip2
    bzip3
    bzip3-grep
    bzip3-tools
    gzip
    ncompress
    p7zip
    unzip
    xz
    zip
)

# Services I like to be sure are set up
DESKTOP_SYSTEMCTL=(
    chrony-wait.service
    man-db-cache-update.service
    man-db-restart-cache-update.service
    plocate-updatedb.timer
)

dnf -y install --skip-unavailable "${DESKTOP_PACKAGES[@]}"

systemctl enable "${DESKTOP_SYSTEMCTL[@]}"

op completion fish > /etc/fish/completions/op
op completion bash > /etc/bash_completion.d/op

starship completion fish > /etc/fish/completions/starship
starship completion bash > /etc/bash_completion.d/starship

npm completion > /etc/bash_completion.d/npm
