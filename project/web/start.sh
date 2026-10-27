#!/bin/sh
# Start the web interface from any working directory; never rebuild the database.
set -eu
script_dir=$(CDPATH= cd -P "$(dirname "$0")" && pwd)
node_bin=${NODE_BIN:-node}
mysql_bin=${MYSQL_BIN:-mysql}

for program in "$node_bin" "$mysql_bin"; do
    if ! command -v "$program" >/dev/null 2>&1; then
        printf 'Program not found: %s. Add it to PATH or set NODE_BIN / MYSQL_BIN.\n' "$program" >&2
        exit 127
    fi
done
if ! "$node_bin" -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 18 ? 0 : 1)'; then
    printf '%s\n' 'Node.js 18 or newer is required.' >&2
    exit 1
fi

exec "$node_bin" "$script_dir/server.js"
