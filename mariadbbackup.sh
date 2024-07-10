#!/bin/bash

# Variables
DB_NAME="omni_test"
DB_USER="root"
DB_PASSWORD="12345"
S3_BUCKET="mariadb-sql-backup"
BACKUP_DIR="/backups"
DATE=$(date +"%Y-%m-%d")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql.gz"

# Crear directorio 
mkdir -p $BACKUP_DIR

# Exportar la base de datos y comprimir
mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME | gzip > $BACKUP_FILE

# Subir el archivo comprimido a S3
aws s3 cp $BACKUP_FILE s3://$S3_BUCKET/

# Eliminar los respaldos locales después de subirlos a S3 (opcional)
rm $BACKUP_FILE

# Dar permisos de ejecución
chmod +x /etc/mariadb_backup.sh

# Agregar al crontab
crontab -e

# Agregar la tarea al crontab

timedatectl status


0 4 * * * /etc/mariadb_backup.sh >> /etc/mariadb_backup.log 2>&1


aws ec2 create-instance-connect-endpoint --subnet-id "terraform.output.subnetid" --security-group-ids "terraform.output.sgid" 