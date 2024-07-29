#!/usr/bin/env bash

# Unofficial Bash Strict Mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

backup_dir="/tmp/$(date '+%Y-%m-%d')"
mkdir "${backup_dir}" && cd "${backup_dir}"
echo $(date)": backup dir "${backup_dir}" created"

envsubst < /root/s3cfg-temp > /root/.s3cfg

# Make actual backup files
# First globals
echo $(date)": Dumping globals..."
pg_dumpall -h $PG_HOST -p $PG_PORT -U $PG_USER -r -f roles.dump
pg_dumpall -h $PG_HOST -p $PG_PORT -U $PG_USER -t -f tablespaces.dump
echo $(date)": Dumping globals completed"

# Getting list of DBs
databases=$(psql -h $PG_HOST -p $PG_PORT -U $PG_USER -qAtX -c "select datname from pg_database where datallowconn order by pg_database_size(oid) desc;")

# And now per-database dumps
echo $(date)": Making per-database dumps..."
for db in $databases; do
  echo "Creating backup of $db"
  pg_dump -h $PG_HOST -p $PG_PORT -U $PG_USER -F d -C -j 8 -f $db.dump $db
  tar --remove-files -cf $db.tar $db.dump
  echo "Backup and compression of $db completed"
done
echo $(date)": Making per-database dumps completed"

echo $(date)": Copying dumps to s3..."
s3cmd sync "${backup_dir}" s3://backupdb/$ENV/
echo $(date)": Copying dumps to s3 completed"

echo $(date)": clear backup dir"
rm -rf "${backup_dir}"

# All done.
exit 0