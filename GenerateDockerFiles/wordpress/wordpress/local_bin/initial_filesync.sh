#!/bin/bash
FILESYNC_LOG_PATH="/var/dev/filesync/"
FILESYNC_LOG_FILE="/var/dev/filesync/status.txt"

test ! -d $FILESYNC_LOG_PATH && mkdir -p $FILESYNC_LOG_PATH
touch $FILESYNC_LOG_FILE

trycount=1
while (( $trycount <6 ))
do
	if [ ! $(grep "RSYNC_COMPLETED" $FILESYNC_LOG_FILE) ] \
	&& rsync -a $WORDPRESS_HOME/ $HOME_SITE_LOCAL_STG/ --exclude $UNISON_EXCLUDED_PATH ; then
		echo "RSYNC_COMPLETED" >> $FILESYNC_LOG_FILE
	fi
	
	if [ $(grep "RSYNC_COMPLETED" $FILESYNC_LOG_FILE) ] && [ ! $(grep "INITIAL_FILESYNC_COMPLETED" $FILESYNC_LOG_FILE) ] \
	&& ln -s $WORDPRESS_HOME/$UNISON_EXCLUDED_PATH $HOME_SITE_LOCAL_STG/$UNISON_EXCLUDED_PATH \
	&& chown -R nginx:nginx $HOME_SITE_LOCAL_STG \
	&& chmod -R 777 $HOME_SITE_LOCAL_STG; then
		echo "INITIAL_FILESYNC_COMPLETED" >> $FILESYNC_LOG_FILE
	fi
	
	trycount=$(($trycount+1))
	if [ $(grep "INITIAL_FILESYNC_COMPLETED" $FILESYNC_LOG_FILE) ]; then
		break
	fi
done

if [ ! $(grep "INITIAL_FILESYNC_COMPLETED" $FILESYNC_LOG_FILE) ]; then
	echo "INITIAL_FILESYNC_FAILED" >> $FILESYNC_LOG_FILE
	return 1
fi

return 0
