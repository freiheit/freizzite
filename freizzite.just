# Freizzite-only recipes, kept out of the Justfile so upstream merges stay
# clean. `just check` already picks up every *.just file.

# Regenerate the logo artefacts from logo/freizzite-logo.svg
[group('Freizzite')]
freizzite-logo:
    uv run --with cairosvg --with pillow logo/render.py
