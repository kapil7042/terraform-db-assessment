#!/bin/bash
set -e

DB_USER="admin"
BACKUP_DIR="./backups"
RESTORE_DB_NAME="bookings_restore"

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file.sql.gz>"
    ls -lh "$BACKUP_DIR" | grep "backup_bookings_"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    BACKUP_FILE="$BACKUP_DIR/$1"
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Backup file not found: $1"
        exit 1
    fi
fi

docker exec booking-db psql -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $RESTORE_DB_NAME"
docker exec booking-db psql -U "$DB_USER" -d postgres -c "CREATE DATABASE $RESTORE_DB_NAME"

gunzip -c "$BACKUP_FILE" | docker exec -i booking-db pg_restore -U "$DB_USER" -d "$RESTORE_DB_NAME"

docker exec booking-db psql -U "$DB_USER" -d "$RESTORE_DB_NAME" -c "SELECT COUNT(*) FROM hotel_bookings;"