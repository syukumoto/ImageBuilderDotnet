#!/bin/bash
FILESYNC_LOG_PATH="/var/dev/filesync/"
FILESYNC_LOG_FILE="/var/dev/filesync/status.txt"

test ! -d $FILESYNC_LOG_PATH && mkdir -p $FILESYNC_LOG_PATH
touch $FILESYNC_LOG_FILE

# wait for initial filesync to complete
while true
do
	if [ -e $FILESYNC_LOG_FILE ]; then
		[ $(grep "INITIAL_FILESYNC_COMPLETED" $FILESYNC_LOG_FILE) ] && break
		[ $(grep "INITIAL_FILESYNC_FAILED" $FILESYNC_LOG_FILE) ] && break
	fi
	
	sleep 5
done

# wait for unison to sync fileserver and local storage before reloading nginx
sleep 10

# reload nginx configuration. Retry 20 times
trycount=0
while (( $trycount < 20 ))
do 
	if cp /usr/src/nginx/wordpress-server.conf /etc/nginx/conf.d/default.conf \
	&& sed -i "s#WORDPRESS_HOME#${HOME_SITE_LOCAL_STG}#g" /etc/nginx/conf.d/default.conf \
	&& /usr/sbin/nginx -s reload; then
		break
	fi
	
	trycount=$(($trycount+1))
done

