#!/usr/bin/env bash
# Rebuild the demo database. Example: ./run_all.sh -u root -p
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mysql_bin=${MYSQL_BIN:-mysql}
command -v "$mysql_bin" >/dev/null || { echo 'MySQL client not found; set MYSQL_BIN or PATH.' >&2; exit 1; }
files=(01_create_database.sql 02_create_tables.sql 03_insert_data.sql 04_views.sql
       06_routines.sql 05_queries.sql 07_crud_samples.sql 08_course_examples.sql 99_verify.sql)
for file in "${files[@]}"; do
  [[ -f "$script_dir/$file" ]] || { echo "Missing: $file" >&2; exit 1; }
done
# One client connection prompts for a password once and stops on the first SQL error.
for file in "${files[@]}"; do
  printf '\n' # Keep adjacent SQL statements separate.
  cat -- "$script_dir/$file"
done | "$mysql_bin" "$@" --default-character-set=utf8mb4 --table
