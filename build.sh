#!/usr/bin/env bash
#
# Builds the Flex-format recipe JSON files from the `<vendor>/<package>/<version>/`
# source folders. Run this every time you change a manifest.json or a template
# file and BEFORE `git push` — Flex consumers fetch the built JSON, not the source
# folder.
#
# Generates:
#   - `<vendor>.<package>.<version>.json`  (one per recipe/version)
#   - `index.json`                         (lists every recipe and its versions)
#
# Requirements: `python3` and `jq` available on PATH.

set -euo pipefail

cd "$(dirname "$0")"

# Discover every <vendor>/<package>/<version>/manifest.json under the repo root.
mapfile -t MANIFESTS < <(find . -mindepth 4 -maxdepth 4 -type f -name manifest.json | sort)

if [ ${#MANIFESTS[@]} -eq 0 ]; then
    echo "no recipes found"
    exit 1
fi

declare -a INDEX_RECIPES=()

for manifest in "${MANIFESTS[@]}"; do
    # ./<vendor>/<package>/<version>/manifest.json -> vendor, package, version
    rel="${manifest#./}"
    vendor=$(echo "$rel" | cut -d'/' -f1)
    package=$(echo "$rel" | cut -d'/' -f2)
    version=$(echo "$rel" | cut -d'/' -f3)
    package_full="${vendor}/${package}"
    package_dotted="${vendor}.${package}"
    src_dir="$(dirname "$manifest")"
    out_file="${package_dotted}.${version}.json"

    echo "building ${out_file} from ${src_dir}"

    # Build a `files` map: every file under $src_dir except manifest.json,
    # path relative to $src_dir, contents split into lines (Flex format).
    files_json=$(python3 - "$src_dir" <<'PY'
import json, os, sys
src = sys.argv[1]
result = {}
for root, _, fs in os.walk(src):
    for f in fs:
        if f == "manifest.json":
            continue
        full = os.path.join(root, f)
        rel = os.path.relpath(full, src)
        with open(full, "rb") as fh:
            raw = fh.read()
        # Flex stores text contents as a list of lines (newline implied between).
        try:
            text = raw.decode("utf-8")
            # Split keeping the trailing empty string if file ends with newline.
            lines = text.split("\n")
        except UnicodeDecodeError:
            lines = [raw.decode("latin-1")]
        result[rel] = {
            "contents": lines,
            "executable": os.access(full, os.X_OK),
        }
print(json.dumps(result))
PY
)

    # Compose the per-recipe JSON: { manifests: { <package>: { manifest, files, ref } } }
    # `ref` is informational; we use a deterministic placeholder (real recipes-contrib
    # uses the git commit hash that introduced the version).
    ref=$(git rev-parse HEAD 2>/dev/null || echo "0000000000000000000000000000000000000000")

    jq -n \
        --arg pkg "$package_full" \
        --slurpfile manifest "$manifest" \
        --argjson files "$files_json" \
        --arg ref "$ref" \
        '{
            manifests: {
                ($pkg): {
                    manifest: $manifest[0],
                    files: $files,
                    ref: $ref
                }
            }
        }' > "$out_file"

    INDEX_RECIPES+=("$package_full|$version")
done

# Build index.json — groups versions per package.
python3 - <<PY > index.json
import json
recipes = {}
$(for r in "${INDEX_RECIPES[@]}"; do
    pkg="${r%|*}"
    ver="${r#*|}"
    echo "recipes.setdefault('$pkg', []).append('$ver')"
done)
for k in recipes:
    recipes[k].sort()
print(json.dumps({
    "recipes": recipes,
    "branch": "main",
    "is_contrib": True,
    "_links": {
        "repository": "github.com/musikhood/symfony-recipes",
        "origin_template": "{package}:{version}@github.com/musikhood/symfony-recipes:main",
        "recipe_template": "https://raw.githubusercontent.com/musikhood/symfony-recipes/main/{package_dotted}.{version}.json",
        "recipe_template_relative": "{package_dotted}.{version}.json"
    }
}, indent=2))
PY

echo
echo "built ${#MANIFESTS[@]} recipe(s)"

# Public repo: fail when sources or the built JSON contain company domains / internal names.
python3 scripts/leak-check.py
echo "leak-check: ok"
ls -la *.json | grep -v "^total"
