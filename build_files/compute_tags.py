#!/usr/bin/env python3
"""Generate metadata-action image tags for custom freizzite builds."""

import os
import re
import sys
import requests

# Environment variables
IMAGE_NAME = os.environ.get("IMAGE_NAME")
BASE_IMAGE = os.environ.get("BASE_IMAGE", "bazzite-nvidia-open")
BASE_TAG = os.environ.get("BASE_TAG", "stable")
REPO_OWNER = os.environ.get("REPO_OWNER")
EVENT_NAME = os.environ.get("EVENT_NAME", "")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")
DATE = os.environ.get("DATE")

HEADERS = {
    "Accept": "application/vnd.github+json",
    "User-Agent": "github-actions",
}
if GITHUB_TOKEN:
    HEADERS["Authorization"] = f"Bearer {GITHUB_TOKEN}"


def request_json(url, params=None):
    response = requests.get(url, headers=HEADERS, params=params)
    response.raise_for_status()
    return response.json()


def package_versions(owner, package):
    for prefix in ["https://api.github.com/orgs", "https://api.github.com/users"]:
        try:
            versions, page = [], 1
            while True:
                response = requests.get(
                    f"{prefix}/{owner}/packages/container/{package}/versions",
                    headers=HEADERS,
                    params={"page": page, "per_page": 100},
                )
                if response.status_code in (403, 404):
                    break
                response.raise_for_status()
                data = response.json()
                if not data:
                    break
                versions.extend(data)
                if len(data) < 100:
                    break
                page += 1
            return versions
        except requests.exceptions.RequestException:
            continue
    return []


def next_daily_sequence(date_str):
    versions = package_versions(REPO_OWNER, IMAGE_NAME)
    seen = {
        int(match.group(1) or 0)
        for version in versions
        for tag in version.get("metadata", {}).get("container", {}).get("tags", [])
        if (match := re.fullmatch(rf"{re.escape(date_str)}(?:\.(\d+))?", tag))
    }
    seq = 0
    while seq in seen:
        seq += 1
    return seq


def extract_base_tags():
    versions = package_versions("ublue-os", BASE_IMAGE)
    prefix = f"{BASE_IMAGE}-"
    for version in versions:
        version_tags = version.get("metadata", {}).get("container", {}).get("tags", [])
        if BASE_TAG in version_tags:
            major = None
            tags = []
            for tag in version_tags:
                if not tag.startswith(prefix):
                    tags.append(f"{prefix}{tag}")
                    if match := re.fullmatch(r"stable-(\d+)(?:\.(.+))?", tag):
                        major = match.group(1)
            return major, sorted(set(tags))
    return None, []


def main():
    if not all([IMAGE_NAME, REPO_OWNER, DATE]):
        missing = [
            k
            for k, v in [
                ("IMAGE_NAME", IMAGE_NAME),
                ("REPO_OWNER", REPO_OWNER),
                ("DATE", DATE),
            ]
            if not v
        ]
        print(f"Missing environment variables: {', '.join(missing)}", file=sys.stderr)
        sys.exit(1)

    seq = next_daily_sequence(DATE)
    daily_tag = DATE if seq == 0 else f"{DATE}.{seq}"

    major, base_tags = extract_base_tags()

    tags = ["latest", daily_tag, f"latest.{daily_tag}"]
    if major:
        tags.append(f"{major}.{daily_tag}")
        tags.extend(base_tags)

    meta_lines = [f"type=raw,value={tag}" for tag in tags]
    meta_lines.append(f"type=sha,enable={str(EVENT_NAME == 'pull_request').lower()}")
    meta_lines.append("type=ref,event=pr")

    print("\n".join(meta_lines))


if __name__ == "__main__":
    main()
