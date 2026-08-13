# shellcheck shell=sh
# Freizzite: overrides bazzite's file of the same name. Identical aliases, with
# --logo appended so fastfetch draws our logo instead of the one bazzite's
# config points at. Appending rather than shipping our own config keeps
# bazzite's module list and bling colours, and leaves their files untouched.
alias neofetch='/usr/bin/fastfetch --color $(/usr/libexec/bazzite-bling-fastfetch) -c /usr/share/ublue-os/bazzite/fastfetch.jsonc --logo-type file --logo /usr/share/ublue-os/freizzite/logo.txt'
alias neowofetch='/usr/bin/fastfetch --color $(/usr/libexec/bazzite-bling-fastfetch) -c /usr/share/ublue-os/bazzite/fastfetch.jsonc --logo-type file --logo /usr/share/ublue-os/freizzite/logo.txt'
alias fastfetch='/usr/bin/fastfetch --color $(/usr/libexec/bazzite-bling-fastfetch) -c /usr/share/ublue-os/bazzite/fastfetch.jsonc --logo-type file --logo /usr/share/ublue-os/freizzite/logo.txt'
