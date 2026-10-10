#!/usr/bin/env bash
# Decide whether a GitHub Release is due, and what goes in it.
#
# A release is due when the newest stable upstream (bazzite) release has been
# built into every published stable image and we have not released it yet.
# Prints a single JSON object on stdout:
#
#   {"release":true,"reason":"...","tag":"44.20261006.1","source_commit":"<sha>",
#    "upstream_url":"https://github.com/ublue-os/bazzite/releases/tag/...",
#    "prev_tag":"44.20260902",
#    "images":[{"name":"freizzite-deck","digest":"sha256:...","base_digest":"sha256:..."}]}
#
# Fails CLOSED: anything we cannot determine means release=false. A missed
# release is a skipped run that the next successful build retries; a wrong
# release is a public artifact.
#
# Inputs, all via the environment:
#   UPSTREAM_REPO  GitHub repo whose stable releases we follow, e.g. ublue-os/bazzite
#   REPO           this repo, e.g. freiheit/freizzite
#   OWNER          ghcr namespace of the published images (lowercased here)
#   VARIANTS       "<image>|<base>|<description>" per line, the build.yml text
#   LABEL_NS       label namespace, default io.github.freiheit.build
#   GH_TOKEN       token for gh (repo read; UPSTREAM_REPO is public)
#
# "Built from release X" is decided by org.opencontainers.image.revision on our
# published image. The Justfile never sets that label, so podman inherits it
# from the pinned base, where bazzite stamps the git commit its release tag
# points at. Matching tag names would not work: bazzite-dx-nvidia carries its
# own version label (44.20261006 vs the release's 44.20261006.1).

set -uo pipefail

: "${UPSTREAM_REPO:?UPSTREAM_REPO is required}"
: "${REPO:?REPO is required}"
: "${OWNER:?OWNER is required}"
: "${VARIANTS:?VARIANTS is required}"
LABEL_NS="${LABEL_NS:-io.github.freiheit.build}"

images='[]'

emit() {
    # emit <release-bool> <reason> [tag] [source-commit] [upstream-url] [prev-tag]
    jq -cn \
        --argjson release "$1" \
        --arg reason "$2" \
        --arg tag "${3:-}" \
        --arg source_commit "${4:-}" \
        --arg upstream_url "${5:-}" \
        --arg prev_tag "${6:-}" \
        --argjson images "${images}" \
        '{release: $release, reason: $reason, tag: $tag, source_commit: $source_commit,
          upstream_url: $upstream_url, prev_tag: $prev_tag, images: $images}'
    exit 0
}

oneline() {
    tr -s '[:space:]' ' ' <<<"$1" | cut -c1-160
}

# ---------------------------------------------------------------------------
# Newest stable upstream release and the commit its tag points at
# ---------------------------------------------------------------------------
if ! upstream="$(gh release list -R "${UPSTREAM_REPO}" \
    --exclude-pre-releases --exclude-drafts --limit 1 --json tagName 2>&1)"; then
    emit false "cannot list ${UPSTREAM_REPO} releases: $(oneline "${upstream}")"
fi
tag="$(jq -r '.[0].tagName // ""' <<<"${upstream}")"
url="https://github.com/${UPSTREAM_REPO}/releases/tag/${tag}"
[[ -z "${tag}" ]] && emit false "no stable release found in ${UPSTREAM_REPO}"

if ! refs="$(git ls-remote --tags "https://github.com/${UPSTREAM_REPO}" "refs/tags/${tag}" 2>&1)"; then
    emit false "cannot resolve tag ${tag} in ${UPSTREAM_REPO}: $(oneline "${refs}")" "${tag}"
fi
# An annotated tag lists a second, peeled "<ref>^{}" line with the commit.
commit="$(awk -v t="refs/tags/${tag}^{}" '$2 == t { print $1 }' <<<"${refs}")"
[[ -z "${commit}" ]] && commit="$(awk -v t="refs/tags/${tag}" '$2 == t { print $1 }' <<<"${refs}")"
[[ -z "${commit}" ]] && emit false "tag ${tag} not found in ${UPSTREAM_REPO}" "${tag}"

# ---------------------------------------------------------------------------
# Already released?
# ---------------------------------------------------------------------------
if existing="$(gh release view "${tag}" -R "${REPO}" --json tagName 2>&1)"; then
    emit false "already released ${tag}" "${tag}" "" "${url}"
elif ! grep -qi 'not found' <<<"${existing}"; then
    emit false "cannot check for an existing ${tag} release: $(oneline "${existing}")" "${tag}"
fi

# ---------------------------------------------------------------------------
# Every published stable image must be built from that commit, all from one
# source commit (recorded in the release notes).
# ---------------------------------------------------------------------------
target=""
while IFS='|' read -r name _base _desc; do
    name="${name//[[:space:]]/}"
    [[ -z "${name}" || "${name}" == \#* ]] && continue
    ref="ghcr.io/${OWNER,,}/${name}:latest"

    if ! manifest="$(skopeo inspect --no-tags "docker://${ref}" 2>&1)"; then
        emit false "cannot inspect ${ref}: $(oneline "${manifest}")" "${tag}"
    fi
    revision="$(jq -r '.Labels["org.opencontainers.image.revision"] // ""' <<<"${manifest}")"
    source="$(jq -r --arg k "${LABEL_NS}.source-commit" '.Labels[$k] // ""' <<<"${manifest}")"
    base_digest="$(jq -r --arg k "${LABEL_NS}.base-digest" '.Labels[$k] // ""' <<<"${manifest}")"
    digest="$(jq -r '.Digest // ""' <<<"${manifest}")"

    if [[ "${revision}" != "${commit}" ]]; then
        emit false "${name}:latest is built from upstream ${revision:0:7}, release ${tag} is ${commit:0:7}" "${tag}"
    fi
    [[ -z "${source}" ]] && emit false "${name}:latest has no ${LABEL_NS}.source-commit label" "${tag}"
    if [[ -n "${target}" && "${source}" != "${target}" ]]; then
        emit false "images disagree on source commit (${target:0:7} vs ${source:0:7} for ${name}); wait for a build of every image" "${tag}"
    fi
    target="${source}"

    images="$(jq -c --arg n "${name}" --arg d "${digest}" --arg b "${base_digest}" \
        '. + [{name: $n, digest: $d, base_digest: $b}]' <<<"${images}")"
done <<<"${VARIANTS}"
[[ -z "${target}" ]] && emit false "no active variants in VARIANTS"

# ---------------------------------------------------------------------------
# Previous release, for the generated changelog range (empty is fine)
# ---------------------------------------------------------------------------
prev="$(gh release list -R "${REPO}" --exclude-pre-releases --exclude-drafts --limit 1 \
    --json tagName -q '.[0].tagName // ""' 2>/dev/null)" || prev=""

count="$(jq 'length' <<<"${images}")"
emit true "all ${count} images built from ${tag} (${commit:0:7}) at ${target:0:7}; not yet released" \
    "${tag}" "${target}" "${url}" "${prev}"
