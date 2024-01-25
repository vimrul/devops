#!/bin/bash

# Define databases and credentials
databases=("db1" "db2" "db3" "db4" "db5" "db6" "db7" "db8" "db9" "db10")
username="postgres"
host="1.1.1.1"
port="5432"
password='pass' # Ensure that the password is correctly formatted if it contains special characters

# Backup directory
backup_directory="/mnt/db-backup/ems-backups"

# Remove backups older than 10 days
find "$backup_directory" -type d -mtime +10 -exec rm -rf {} \;

# Create a backup directory based on current date and time
backup_dir=$(date +'%d-%m-%Y_%I-%M-%p')
backup_directory="$backup_directory/$backup_dir"
mkdir -p "$backup_directory"

# Loop through each database and perform backup
for db in "${databases[@]}"; do
    backup_file="$backup_directory/$db"

    # Set PGPASSWORD to avoid password prompt
    export PGPASSWORD="$password"

    # Perform backup using pg_dump in binary format (all tables/schemas)
    /usr/bin/pg_dump --verbose --host="$host" --port="$port" --username="$username" --format=c --file="$backup_file" "$db"

    # Unset PGPASSWORD after backup
    unset PGPASSWORD
done
