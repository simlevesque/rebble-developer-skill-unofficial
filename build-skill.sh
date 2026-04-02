#!/usr/bin/env bash
# build-skill.sh — Converts Rebble developer docs into a multi-file skill
#
# Output layout (./):
#   SKILL.md               — lean skill instructions + topic index
#   app-resources.md       — one file per guide section (15 total)
#   communication.md
#   examples.md            — 29 example apps with GitHub links
#   ... etc.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/developer.rebble.io/source"
OUT_DIR="$SCRIPT_DIR"

# Pull latest docs from submodule
echo "Updating submodule..."
git -C "$SCRIPT_DIR" submodule update --init --remote developer.rebble.io

echo "Source : $SOURCE_DIR"
echo "Output : $OUT_DIR/"

find "$OUT_DIR" -maxdepth 1 -name "*.md" ! -name "README.md" -delete

# ---------------------------------------------------------------------------
# Python processor: strip front matter + Liquid from a single file
# ---------------------------------------------------------------------------
PYPROC="$(mktemp /tmp/rebble_proc_XXXXXX.py)"
trap 'rm -f "$PYPROC"' EXIT

cat > "$PYPROC" <<'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, encoding='utf-8', errors='replace') as f:
    content = f.read()

fm_title = ''
fm_desc = ''
body = content

m = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
if m:
    fm_block = m.group(1)
    body = content[m.end():]

    t = re.search(r'^title:\s*(.+)$', fm_block, re.MULTILINE)
    if t:
        fm_title = t.group(1).strip().strip('"\'')

    d = re.search(r'^description:\s*\|?\s*\n((?:[ \t]+.+\n?)+)', fm_block, re.MULTILINE)
    if d:
        fm_desc = re.sub(r'\s+', ' ', d.group(1)).strip()
    else:
        d2 = re.search(r'^description:\s*(.+)$', fm_block, re.MULTILINE)
        if d2:
            fm_desc = d2.group(1).strip().strip('"\'')

# Clean Liquid/Jekyll tags
body = re.sub(r'\{%-?\s.*?-?%\}', '', body, flags=re.DOTALL)
body = re.sub(r'\{\{.*?\}\}', '', body, flags=re.DOTALL)
body = re.sub(r'\{%\s*guide_link\s+([^\s%]+)[^%]*%\}', r'(see guide: \1)', body)
body = re.sub(r'<!--.*?-->', '', body, flags=re.DOTALL)
body = re.sub(r'<(script|style)[^>]*>.*?</\1>', '', body, flags=re.DOTALL | re.IGNORECASE)
body = re.sub(r'\n{3,}', '\n\n', body)
body = body.strip()

print(f'FM_TITLE={fm_title}')
print(f'FM_DESC={fm_desc}')
print('FM_BODY_START')
print(body)
PYEOF

get_title() { python3 "$PYPROC" "$1" | grep '^FM_TITLE=' | cut -d= -f2-; }
get_body()  { python3 "$PYPROC" "$1" | awk '/^FM_BODY_START/{f=1;next} f{print}'; }
get_desc()  { python3 "$PYPROC" "$1" | grep '^FM_DESC=' | cut -d= -f2-; }

to_title_case() {
    echo "$1" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1'
}

# ---------------------------------------------------------------------------
# Generate one topic file per guide section
# ---------------------------------------------------------------------------
declare -A SECTION_DESCS
declare -a SECTIONS

while IFS= read -r section_dir; do
    section="$(basename "$section_dir")"
    SECTIONS+=("$section")
    outfile="$OUT_DIR/${section}.md"
    heading="$(to_title_case "$section")"

    {
        echo "<!-- Generated from pebble-dev/developer.rebble.io (Apache 2.0) with modifications -->"
        echo ""
        echo "# $heading"
        echo ""

        # Use index.md description if available
        if [[ -f "$section_dir/index.md" ]]; then
            idx_desc="$(get_desc "$section_dir/index.md")"
            if [[ -n "$idx_desc" ]]; then
                SECTION_DESCS["$section"]="$idx_desc"
                echo "> $idx_desc"
                echo ""
            fi
        fi

        # Write each guide in the section (index last)
        while IFS= read -r file; do
            title="$(get_title "$file")"
            [[ -z "$title" ]] && title="$(to_title_case "$(basename "$file" .md)")"
            body="$(get_body "$file")"
            [[ -z "$body" ]] && continue

            echo "## $title"
            echo ""
            echo "$body"
            echo ""

        done < <(find "$section_dir" -maxdepth 1 -name "*.md" ! -name "index.md" | sort; \
                 find "$section_dir" -maxdepth 1 -name "index.md")

    } > "$outfile"

    lines="$(wc -l < "$outfile")"
    echo "  wrote ${section}.md ($lines lines)"

done < <(find "$SOURCE_DIR/_guides" -mindepth 1 -maxdepth 1 -type d | sort)

# ---------------------------------------------------------------------------
# Generate examples.md from _data/examples.yaml
# ---------------------------------------------------------------------------
python3 - "$SOURCE_DIR/_data/examples.yaml" "$OUT_DIR/examples.md" <<'PYEOF'
import sys, yaml

src, dst = sys.argv[1], sys.argv[2]
with open(src, encoding='utf-8') as f:
    examples = yaml.safe_load(f)

lines = ["<!-- Generated from pebble-dev/developer.rebble.io (Apache 2.0) with modifications -->\n",
         "# Example Apps\n",
         "Curated Pebble example apps on GitHub. Each repo is a complete, buildable project.\n"]

# Featured first, then rest alphabetically
featured = [e for e in examples if e.get('featured')]
rest     = sorted([e for e in examples if not e.get('featured')], key=lambda e: e['title'])

for e in featured + rest:
    title    = e.get('title', '')
    repo     = e.get('repo', '')
    desc     = (e.get('description') or '').strip()
    langs    = ', '.join(e.get('languages') or [])
    tags     = ', '.join(e.get('tags') or [])
    platforms = ', '.join(e.get('hardware_platforms') or [])
    url      = f"https://github.com/{repo}" if repo else ''

    lines.append(f"## {title}\n")
    if url:
        lines.append(f"[{repo}]({url})\n")
    if desc:
        lines.append(f"\n{desc}\n")
    meta = []
    if langs:     meta.append(f"**Languages**: {langs}")
    if platforms: meta.append(f"**Platforms**: {platforms}")
    if tags:      meta.append(f"**Tags**: {tags}")
    if meta:
        lines.append("\n" + " · ".join(meta) + "\n")
    lines.append("\n")

with open(dst, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
PYEOF

lines="$(wc -l < "$OUT_DIR/examples.md")"
echo "  wrote examples.md ($lines lines)"

# ---------------------------------------------------------------------------
# Generate lean SKILL.md
# ---------------------------------------------------------------------------
{
cat <<'HEADER'
---
name: rebble-developer
description: Rebble/Pebble watchapp developer documentation. Use when helping develop Pebble watchapps, answering questions about the Pebble C SDK, PebbleKit JS/Android/iOS, Rocky.js, app configuration, communication, UI layers, resources, publishing, or any Pebble/Rebble platform topic.
---

# Rebble Developer Skill

You are an expert in Pebble/Rebble smartwatch app development.

## Platform Overview

- **Language**: C (watchapp) + JavaScript (PebbleKit JS / Rocky.js for companion/web)
- **Targets**: Aplite (B&W), Basalt (color 144×168), Chalk (round 180×180), Diorite, Emery
- **Build tool**: `pebble` CLI; apps packaged as `.pbw`
- **Key APIs**: `Window`, `Layer`, `TextLayer`, `BitmapLayer`, `AppMessage`, `AppTimer`, `Persistent Storage`, `DataLogging`, `Timeline`, `Wakeup`
- **PebbleKit JS**: runs on phone; bridge between watch C app and internet/phone sensors
- **Rocky.js**: write watchfaces in JavaScript directly on the watch

## How to use these docs

Detailed reference files live alongside this skill. Read the relevant file when answering questions about that topic:

HEADER

for section in "${SECTIONS[@]}"; do
    heading="$(to_title_case "$section")"
    desc="${SECTION_DESCS[$section]:-}"
    if [[ -n "$desc" ]]; then
        echo "- **\`${section}.md\`** — $heading: $desc"
    else
        echo "- **\`${section}.md\`** — $heading"
    fi
done
echo "- **\`examples.md\`** — Example Apps: 29 curated example projects on GitHub"


} > "$OUT_DIR/SKILL.md"

echo "  wrote SKILL.md"

# ---------------------------------------------------------------------------
# Stats
# ---------------------------------------------------------------------------
total_files=$(ls "$OUT_DIR"/*.md | wc -l)
total_size=$(du -sh "$OUT_DIR" | cut -f1)
echo ""
echo "Done! $total_files files, $total_size total in $OUT_DIR/"
