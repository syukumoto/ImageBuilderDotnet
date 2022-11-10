#!/bin/bash

#import database

trycount=$1
if (( $trycount > 0 )); then
	if [[ $MIGRATION_IN_PROGRESS ]] && [[ "$MIGRATION_IN_PROGRESS" == "true" || "$MIGRATION_IN_PROGRESS" == "TRUE" || "$MIGRATION_IN_PROGRESS" == "True" ]]  \
	&& [[ $MIGRATE_NEW_DATABASE_NAME ]] && [[ $MIGRATE_MYSQL_DUMP_PATH ]] \
	&& [ ! $(grep "MYSQL_DB_IMPORT_COMPLETED" $MYSQL_IMPORT_STATUSFILE_PATH) ]; then
		if apk add mysql-client --no-cache \
		&& mysql -h $DATABASE_HOST -u $DATABASE_USERNAME --password=$DATABASE_PASSWORD -e "DROP DATABASE IF EXISTS $MIGRATE_NEW_DATABASE_NAME; CREATE DATABASE $MIGRATE_NEW_DATABASE_NAME;" --ssl=true \
		&& mysql -h $DATABASE_HOST -u $DATABASE_USERNAME --password=$DATABASE_PASSWORD $MIGRATE_NEW_DATABASE_NAME < $MIGRATE_MYSQL_DUMP_PATH  --ssl=true; then
			test ! -e $MYSQL_IMPORT_STATUSFILE_PATH && mkdir -p $MYSQL_IMPORT_STATUSFILE_DIR && touch $MYSQL_IMPORT_STATUSFILE_PATH
			echo "MYSQL_DB_IMPORT_COMPLETED" >> $MYSQL_IMPORT_STATUSFILE_PATH
		else
			service atd start
			nextcount=$(($trycount-1))
			echo "bash /usr/local/bin/migrate.sh $nextcount" | at now +0 minutes
		fi
	fi
else
	echo "MYSQL_DB_IMPORT_FAILED" >> $MYSQL_IMPORT_STATUSFILE_PATH
fi
