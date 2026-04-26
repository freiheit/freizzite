#!/bin/bash
set -ouex pipefail

# Desktop variants:
# Includes: chezmoi, starship, 1password, VSCode, and programming tools

dnf5 -y copr enable atim/starship

# https://code.visualstudio.com/docs/setup/linux#_rhel-fedora-and-centos-based-distributions
rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo

# https://support.1password.com/install-linux/#fedora-or-red-hat-enterprise-linux
rpm --import https://downloads.1password.com/linux/keys/1password.asc
echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo

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

    # Website thingy
    hugo
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

# redirect $HOME because starship and 1password/op really like to write cache files under /root/
HOME=/var/tmp starship completions fish > /etc/fish/completions/starship
HOME=/var/tmp starship completions bash > /etc/bash_completion.d/starship

HOME=/var/tmp op --cache=false completion fish > /etc/fish/completions/op
HOME=/var/tmp op --cache=false completion bash > /etc/bash_completion.d/op

npm completion > /etc/bash_completion.d/npm
