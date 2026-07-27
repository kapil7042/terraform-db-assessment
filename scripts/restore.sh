#!/bin/bash
set -e

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-bookings}"
DB_USER="${DB_USER:-admin}"
DB_PASSWORD="${DB_PASSWORD:-admin123}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RESTORE_DB_NAME="${RESTORE_DB_NAME:-bookings_restore}"

list_backups() {
    echo "Available backups:"
    ls -lh "$BACKUP_DIR" | grep "backup_${DB_NAME}_" | awk '{print $9, "("$5")"}'
}

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file.sql.gz>"
    list_backups
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    BACKUP_FILE="$BACKUP_DIR/$1"
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "✗ Backup file not found: $1"
        list_backups
        exit 1
    fi
fi

export PGPASSWORD="$DB_PASSWORD"

echo "Checking if database $RESTORE_DB_NAME exists..."
DB_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -tAc "SELECT 1 FROM pg_database WHERE datname='$RESTORE_DB_NAME'")

if [ "$DB_EXISTS" = "1" ]; then
    echo "Database $RESTORE_DB_NAME exists. Dropping it..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "DROP DATABASE $RESTORE_DB_NAME"
fi

echo "Creating database $RESTORE_DB_NAME..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "CREATE DATABASE $RESTORE_DB_NAME"

echo "Restoring from backup: $BACKUP_FILE"
gunzip -c "$BACKUP_FILE" | pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$RESTORE_DB_NAME"

if [ $? -eq 0 ]; then
    echo "✓ Restore completed successfully"
    echo -e "\nVerifying restore:"
    echo "Tables and row counts:"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$RESTORE_DB_NAME" -c "
        SELECT 
            table_name, 
            (xpath('/row/cnt/text()', query_to_xml(format('SELECT count(*) as cnt FROM %I', table_name), false, true, '')))[1]::text::int as row_count
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        ORDER BY table_name;
    "
    echo -e "\n✓ Database restored to: $RESTORE_DB_NAME"
    echo "Access with: psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $RESTORE_DB_NAME"
else
    echo "✗ Restore failed"
    exit 1
fi