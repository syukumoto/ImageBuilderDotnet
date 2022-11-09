#!/bin/bash

#import database
mysql_import_statusfile_path="/home/dev/migrate/mysql/mysql_import_status.txt"
trycount=$1
if (( $trycount > 0 )); then
	if [[ $MIGRATION_IN_PROGRESS ]] && [[ "$MIGRATION_IN_PROGRESS" == "true" || "$MIGRATION_IN_PROGRESS" == "TRUE" || "$MIGRATION_IN_PROGRESS" == "True" ]]  \
	&& [[ $MIGRATE_NEW_DATABASE_NAME ]] && [[ $MIGRATE_MYSQL_DUMP_PATH ]] \
	&& [ ! $(grep "MYSQL_DB_IMPORT_COMPLETED" $mysql_import_statusfile_path) ]; then
		if apk add mysql-client --no-cache \
		&& mysql -h $DATABASE_HOST -u $DATABASE_USERNAME --password=$DATABASE_PASSWORD -e "DROP DATABASE IF EXISTS $MIGRATE_NEW_DATABASE_NAME; CREATE DATABASE $MIGRATE_NEW_DATABASE_NAME;" --ssl=true \
		&& mysql -h $DATABASE_HOST -u $DATABASE_USERNAME --password=$DATABASE_PASSWORD $MIGRATE_NEW_DATABASE_NAME < $MIGRATE_MYSQL_DUMP_PATH  --ssl=true; then
			test ! -e $mysql_import_statusfile_path && touch $mysql_import_statusfile_path
			echo "MYSQL_DB_IMPORT_COMPLETED" >> $mysql_import_statusfile_path
		else
			service atd start
			nextcount=$(($trycount-1))
			echo "bash /usr/local/bin/migrate.sh $nextcount" | at now +0 minutes
		fi
	fi
fi

