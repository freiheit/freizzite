#!/bin/bash
set -ouex pipefail

# shellcheck source=/dev/null
source /ctx/lib-verify.sh

# Desktop variants:
# Includes: chezmoi, starship, 1password, VSCode, and programming tools

dnf5 -y copr enable atim/starship
dnf5 -y copr enable scottames/ghostty
# terra (enabled by default in the bazzite base image) also ships ghostty;
# so give ghostty copr winning priority.
dnf5 config-manager setopt 'copr:copr.fedorainfracloud.org:scottames:ghostty.priority=50'

# https://code.visualstudio.com/docs/setup/linux#_rhel-fedora-and-centos-based-distributions
rpm --import https://packages.microsoft.com/keys/microsoft.asc
dnf5 config-manager addrepo --id=code \
  --set=name="Visual Studio Code" \
  --set=baseurl=https://packages.microsoft.com/yumrepos/vscode \
  --set=gpgkey=https://packages.microsoft.com/keys/microsoft.asc \
  --set=gpgcheck=1 --set=type=rpm-md

# https://support.1password.com/install-linux/#fedora-or-red-hat-enterprise-linux
rpm --import https://downloads.1password.com/linux/keys/1password.asc
# shellcheck disable=SC2016 # $basearch is dnf's variable, not the shell's
dnf5 config-manager addrepo --id=1password \
  --set=name="1Password Stable Channel" \
  --set=baseurl='https://downloads.1password.com/linux/rpm/stable/$basearch' \
  --set=gpgkey=https://downloads.1password.com/linux/keys/1password.asc \
  --set=gpgcheck=1 --set=repo_gpgcheck=1

# https://support.mozilla.org/en-US/kb/install-firefox-linux#w_install-firefox-rpm-package-recommended
dnf5 config-manager addrepo --id=mozilla \
  --set=baseurl=https://packages.mozilla.org/rpm/firefox \
  --set=gpgkey=https://packages.mozilla.org/rpm/firefox/signing-key.gpg \
  --set=gpgcheck=1 --set=repo_gpgcheck=0 --set=priority=10

# https://code.claude.com/docs/en/setup#dnf
dnf5 config-manager addrepo --id=claude-code \
  --set=name="Claude Code" \
  --set=baseurl=https://downloads.claude.ai/claude-code/rpm/stable \
  --set=gpgkey=https://downloads.claude.ai/keys/claude-code.asc \
  --set=gpgcheck=1

DESKTOP_PACKAGES=(
    # I'd prefer non-flatpak browser so I can do 1password desktop integration easier
    firefox

    # 1Password (Integrations struggle in Flatpak install)
    1password
    1password-cli

    # terminal
    ghostty

    # LLM CLI
    claude-code

    # GUI apps pulled off Flathub: thin RPMs over Qt/KDE/GTK libs already in the image
    calibre
    flatseal
    gnome-firmware
    gnome-font-viewer
    gwenview
    haruna
    kcalc
    mediawriter
    rssguard
    vlc
)

DESKTOP_TERRA_PACKAGES=(

    # Fave prompt
    starship

    # Other stuff (terra)
    lazyssh

    # Programming stuff I find handy
    code
    gh
    git-filter-repo
    git-koji # terra
    git-lfs
    jq
    nodejs
    nodejs-npm
    perl-App-cpanminus
    perl-CPAN
    perltidy
    pre-commit
    ripgrep
    ruff
    ShellCheck
    shfmt
    sqlite
    sqlite-analyzer
    sqlite-debug
    sqlite-doc
    sqlite-tools
    uv
    yamllint
    yq

    # Handy tools
    fzf
    thefuck
    plocate
    mtr
    netcat
    rclone
    tldr

    # Prefer "native" over flathub so Rich Presence works better (terra)
    vesktop
    discord
    discord-canary

    # Various (de)compression tools
    bzip2
    bzip3
    bzip3-grep
    bzip3-tools
    gzip
    ncompress

    # Website thingy
    hugo

    # GUI apps pulled off Flathub (terra). lact needs a root daemon with direct
    # amdgpu access, which the Flatpak can only approximate.
    kontainer
    lact
    protonplus
)

# Services I like to be sure are set up
DESKTOP_SYSTEMCTL=(
    chrony-wait.service
    lactd.service
    man-db-cache-update.service
    man-db-restart-cache-update.service
    plocate-updatedb.timer
    podman.socket
)

dnf -y install --skip-unavailable "${DESKTOP_PACKAGES[@]}"
dnf -y install --skip-unavailable --enable-repo=terra "${DESKTOP_TERRA_PACKAGES[@]}"

systemctl enable "${DESKTOP_SYSTEMCTL[@]}"

# redirect $HOME because starship and 1password/op really like to write cache files under /root/
HOME=/var/tmp starship completions fish > /etc/fish/completions/starship.fish
HOME=/var/tmp starship completions bash > /etc/bash_completion.d/starship

HOME=/var/tmp op --cache=false completion fish > /etc/fish/completions/op.fish
HOME=/var/tmp op --cache=false completion bash > /etc/bash_completion.d/op

npm completion > /etc/bash_completion.d/npm

# The HOME=/var/tmp redirects above leave dotfiles (and an op daemon socket)
# behind. /var/tmp is not a build mount, so they ship in the image and
# `bootc container lint` flags them under var-tmpfiles.
rm -rf /var/tmp/.config /var/tmp/.cache /var/tmp/.local

# Fail the build if any requested package didn't actually get installed.
# Both lists: `--skip-unavailable` silently drops anything unresolvable, so
# an unverified list is a list that can quietly go missing.
verify_packages_installed "${DESKTOP_PACKAGES[@]}" "${DESKTOP_TERRA_PACKAGES[@]}"
