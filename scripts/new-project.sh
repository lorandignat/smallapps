#!/usr/bin/env bash
# Create a new project skeleton inside the apps workspace.
#
#   ./scripts/new-project.sh audiobooks
#   ./scripts/new-project.sh audiobooks "Audiobooks"
#
# It copies templates/project/ to <slug>/ and fills in {{PROJECT}}, {{TITLE}} and
# {{DATE}}. It does not touch git and does not add the registry row: the BA does
# both, deliberately, so that every project has a recorded phase.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$ROOT/templates/project"

usage() {
  sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 1
}

[ $# -ge 1 ] || usage
SLUG="$1"
TITLE="${2:-}"

case "$SLUG" in
  .* | */* | *\\* | *" "*)
    echo "error: slug must be a single lowercase name, no dots, slashes or spaces" >&2
    exit 1
    ;;
esac

if ! printf '%s' "$SLUG" | grep -Eq '^[a-z0-9][a-z0-9_-]*$'; then
  echo "error: slug must match ^[a-z0-9][a-z0-9_-]*\$ (lowercase, dashes or underscores)" >&2
  exit 1
fi

case "$SLUG" in
  docs | templates | scripts | .opencode | .tooling | node_modules)
    echo "error: '$SLUG' is reserved for the workspace" >&2
    exit 1
    ;;
esac

DEST="$ROOT/$SLUG"
if [ -e "$DEST" ]; then
  echo "error: $SLUG/ already exists" >&2
  exit 1
fi

if [ -z "$TITLE" ]; then
  TITLE="$(printf '%s' "$SLUG" | tr '_-' '  ' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}}1')"
fi

TODAY="$(date +%F)"

cp -R "$TEMPLATE" "$DEST"

python3 - "$DEST" "$SLUG" "$TITLE" "$TODAY" <<'PY'
import pathlib, sys

dest, slug, title, today = sys.argv[1:5]
root = pathlib.Path(dest)
for path in root.rglob("*"):
    if not path.is_file():
        continue
    text = path.read_text(encoding="utf-8")
    if "{{" not in text:
        continue
    path.write_text(
        text.replace("{{PROJECT}}", slug)
        .replace("{{TITLE}}", title)
        .replace("{{DATE}}", today)
        .replace("{{one_liner}}", "One line on what this app does and for whom."),
        encoding="utf-8",
    )
PY

cat <<EOF

Created $SLUG/ ($TITLE)

Next:
  1. Fill the header of $SLUG/README.md and $SLUG/docs/STACK.md.
  2. Add a row to docs/PROJECTS.md (phase: intake).
  3. cd $SLUG && opencode        then   /idea

Nothing is committed yet on purpose.
EOF
