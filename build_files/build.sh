#!/bin/bash

set -ouex pipefail

BUILD_VARIANT="${BUILD_VARIANT:-bazzite-dx-nvidia}"
echo "Building variant: ${BUILD_VARIANT}"

# Workaround for bootc-image-builder ISO depsolve bug
# https://github.com/osbuild/bootc-image-builder/issues/1188
# BIB depsolve runs in an isolated environment and can't resolve file:// GPG
# key paths from the source container image. Disable gpgcheck for affected repos
# so ISO builds can complete. Remove once BIB fixes path translation for GPG keys.
for repo in /etc/yum.repos.d/terra*.repo; do
    if [ -f "$repo" ] && grep -q 'gpgkey=file://' "$repo"; then
        sed -i -e 's/^gpgcheck=1/gpgcheck=0/' -e 's/^repo_gpgcheck=1/repo_gpgcheck=0/' "$repo"
    fi
done

# Terra's metalink advertises a repomd checksum that its mirrors -- including
# the fyralabs origin -- do not always have yet. dnf rejects every mirror
# ("Usable URL not found"), the repo goes unusable, and --skip-unavailable then
# drops every terra package without failing. Go straight to the origin: no
# advertised hash, no mirror race. terra-release ships the baseurl commented
# out next to each metalink.
sed -i -e 's/^metalink=/#metalink=/' -e 's/^#baseurl=/baseurl=/' /etc/yum.repos.d/terra*.repo

# Terra publishes one repo per Fedora release and can lag a Fedora bump; fall
# back to the previous release while the current one does not exist. Only a
# definite 404 counts -- a network failure reports 000 and is left alone, so a
# blip cannot silently pin the wrong release.
terra_release="$(rpm -E %fedora)"
terra_status="$(curl -sSo /dev/null -w '%{http_code}' \
    "https://repos.fyralabs.com/terra${terra_release}/repodata/repomd.xml" || true)"
if [ "${terra_status}" = "404" ]; then
    echo "NOTE: terra${terra_release} is not published; falling back to terra$((terra_release - 1))"
    sed -i "s/[$]releasever/$((terra_release - 1))/g" /etc/yum.repos.d/terra*.repo
fi

# Copy the contents of system_files/ into the image
cp -avf "/ctx/system_files"/. /

# Snapshot /var so we can tell what this build adds. /var is machine-local on
# bootc and is only seeded on a fresh install, so anything created here has to
# be recreated by tmpfiles.d rather than shipped in the image.
# (/var/cache and /var/log are build mounts, not part of the image.)
var_dirs() {
    find /var -mindepth 1 \
        \( -path /var/cache -o -path /var/log -o -path /var/tmp \) -prune -o \
        -type d -print | sort
}
var_dirs >/tmp/var-dirs-before

######################
# common build steps #
######################
/ctx/build-common.sh

################################
# variant-specific build steps #
################################
case "${BUILD_VARIANT}" in
    bazzite-deck)
        echo "Deck variant: nothing extra for now"
        ;;
    *)
        echo "Running desktop-specific build..."
        /ctx/build-desktop.sh
        ;;
esac

####################
# image hygiene    #
####################

# 1Password's scriptlets create these groups directly instead of shipping
# sysusers.d, which `bootc container lint` flags. Declare the groups without
# pinning a GID: the number the build container allocates is not the number a
# real system has (builds land in the 1000+ range, where human users live), and
# systemd-sysusers never renumbers a group that already exists -- so a recorded
# GID is at best inert and at worst collides with a real user's group.
# `docker` is flagged too but comes from the bazzite-dx base -- pinning a GID we
# do not own would fight upstream if they ever change it.
# `|| true` because getent exits 2 when it finds none of them, and pipefail
# would otherwise abort the build.
getent group onepassword onepassword-cli onepassword-mcp |
    sed 's/^\([^:]*\):.*/g \1 -/' >/usr/lib/sysusers.d/freizzite-1password.conf || true
[ -s /usr/lib/sysusers.d/freizzite-1password.conf ] ||
    rm -f /usr/lib/sysusers.d/freizzite-1password.conf

# dnf4 state (dragged in by etckeeper-dnf/dnf-plugins-core), rpm-state and
# /run/dnf are build artifacts. `dnf clean all` does not touch these -- the
# caches it clears live on a build mount and never enter the image. Drop them
# before the /var snapshot so we do not bother recreating them at boot.
rm -rf /var/lib/dnf /var/lib/rpm-state /run/dnf

# Everything else this build added under /var gets a tmpfiles.d entry (so it is
# recreated on a fresh deploy) and is then removed from the image.
var_dirs >/tmp/var-dirs-after
comm -13 /tmp/var-dirs-before /tmp/var-dirs-after >/tmp/var-dirs-new
{
    echo "# Generated at image build time by build_files/build.sh"
    while read -r d; do
        printf 'd %s 0%s %s %s - -\n' \
            "$d" "$(stat -c '%a' "$d")" "$(stat -c '%U' "$d")" "$(stat -c '%G' "$d")"
    done </tmp/var-dirs-new
} >/usr/lib/tmpfiles.d/freizzite-var.conf

tac /tmp/var-dirs-new | while read -r d; do
    rm -rf "$d"
done

###################
# image branding  #
###################
# Last, after every dnf transaction: /usr/lib/os-release is rpm-owned.
/ctx/image-info
