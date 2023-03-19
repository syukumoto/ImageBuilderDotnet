#!/bin/bash

test ! -d $FILESYNC_STATUS_FILE_DIR && mkdir -p $FILESYNC_STATUS_FILE_DIR
touch $FILESYNC_STATUS_FILE_PATH

# wait for initial filesync to complete
while [ -e $FILESYNC_STATUS_FILE_PATH ] && [ ! $(grep "INITIAL_FILESYNC_COMPLETED" $FILESYNC_STATUS_FILE_PATH) ]
do	
	sleep 10
done

# wait for unison-fsmonitor to come up
while [ `ps -ef | grep unison-fsmonitor | grep -v grep | wc -l` -le 0 ]
do
	sleep 10
done

# wait 3min for unison to sync fileserver and local storage before reloading nginx
sleep 180

# reload nginx configuration. Retry 20 times
trycount=0
while (( $trycount < 50 ))
do 

	if sed -i "s#${WORDPRESS_HOME}#${HOME_SITE_LOCAL_STG}#g" /etc/nginx/conf.d/default.conf \
	&& /usr/sbin/nginx -s reload; then
		break
	fi
	
	trycount=$(($trycount+1))
done
