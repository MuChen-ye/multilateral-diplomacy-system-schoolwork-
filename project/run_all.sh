#!/bin/sh
# Rebuild the demo database. All remaining arguments go to the MySQL client.
set -eu

if [ "${1:-}" = "--help" ]; then
    printf '%s\n' 'Usage: sh project/run_all.sh [mysql options]' \
        '  Password login: -u root -p' \
        '  Linux socket authentication: sudo sh project/run_all.sh -u root' \
        '  Custom client: MYSQL_BIN="/path/to/mysql" sh project/run_all.sh -u root -p' \
        'Requires MySQL 8.0.16+. Rebuilds and clears the project database.'
    exit 0
fi

script_dir=$(CDPATH= cd -P "$(dirname "$0")" && pwd)
mysql_bin=${MYSQL_BIN:-mysql}
if ! command -v "$mysql_bin" >/dev/null 2>&1; then
    printf '%s\n' 'MySQL client not found. Add its bin directory to PATH or set MYSQL_BIN.' >&2
    exit 127
fi

files='01_create_database.sql 02_create_tables.sql 03_insert_data.sql 04_views.sql
06_routines.sql 05_queries.sql 07_crud_samples.sql 08_course_examples.sql 99_verify.sql'
for file in $files; do
    if [ ! -r "$script_dir/$file" ]; then
        printf 'Missing or unreadable SQL file: %s\n' "$script_dir/$file" >&2
        exit 1
    fi
done

# Assemble before connecting: no partial input, pipeline SIGPIPE or repeated prompts.
sql_file=$(mktemp "${TMPDIR:-/tmp}/diplomacy-sql.XXXXXX")
trap 'rm -f "$sql_file"' 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
for file in $files; do
    printf '\n-- File: %s\n' "$file" >> "$sql_file"
    cat "$script_dir/$file" >> "$sql_file"
done

printf '%s\n' 'Rebuilding the project database (existing data will be cleared).'
# Keep defaults-file options first; force batch mode and stop at the first SQL error.
if "$mysql_bin" "$@" --default-character-set=utf8mb4 --batch --skip-force --table < "$sql_file"; then
    printf '%s\n' 'All scripts applied successfully.'
else
    result=$?
    printf 'Database rebuild stopped (exit %s). See the MySQL error above.\n' "$result" >&2
    exit "$result"
fi
