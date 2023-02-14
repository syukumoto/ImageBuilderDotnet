#!/bin/bash

test ! -d $FILESYNC_STATUS_FILE_DIR && mkdir -p $FILESYNC_STATUS_FILE_DIR
touch $FILESYNC_STATUS_FILE_PATH

# wait for initial filesync to complete
while [ -e $FILESYNC_STATUS_FILE_PATH ] && [ ! $(grep "INITIAL_FILESYNC_COMPLETED" $FILESYNC_STATUS_FILE_PATH) ]
do	
	sleep 10
done

# wait 5min for unison to sync fileserver and local storage before reloading nginx
sleep 300

# reload nginx configuration. Retry 20 times
trycount=0
while (( $trycount < 50 ))
do 
	if cp /usr/src/nginx/wordpress-server.conf /etc/nginx/conf.d/default.conf \
	&& sed -i "s#WORDPRESS_HOME#${HOME_SITE_LOCAL_STG}#g" /etc/nginx/conf.d/default.conf \
	&& /usr/sbin/nginx -s reload; then
		break
	fi
	
	trycount=$(($trycount+1))
done

