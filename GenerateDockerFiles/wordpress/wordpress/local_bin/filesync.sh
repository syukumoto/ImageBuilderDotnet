#!/bin/bash

test ! -d $FILESYNC_STATUS_FILE_DIR && mkdir -p $FILESYNC_STATUS_FILE_DIR
touch $FILESYNC_STATUS_FILE_PATH

#initial copy from /home/site/wwwroot to /var/www/wordpress
if [ ! $(grep "RSYNC_COMPLETED" $FILESYNC_STATUS_FILE_PATH) ] \
&& rsync -a $WORDPRESS_HOME/ $HOME_SITE_LOCAL_STG/ --exclude $UNISON_EXCLUDED_PATH ; then
	echo "RSYNC_COMPLETED" >> $FILESYNC_STATUS_FILE_PATH
fi

# Update file permissions an directory ownership after initial copy
if [ $(grep "RSYNC_COMPLETED" $FILESYNC_STATUS_FILE_PATH) ] && [ ! $(grep "INITIAL_FILESYNC_COMPLETED" $FILESYNC_STATUS_FILE_PATH) ] \
&& ln -s $WORDPRESS_HOME/$UNISON_EXCLUDED_PATH $HOME_SITE_LOCAL_STG/$UNISON_EXCLUDED_PATH \
&& chown -R nginx:nginx $HOME_SITE_LOCAL_STG \
&& chmod -R 777 $HOME_SITE_LOCAL_STG; then
	echo "INITIAL_FILESYNC_COMPLETED" >> $FILESYNC_STATUS_FILE_PATH
fi

# exit if initial filesync failed to restart the process
if [ ! $(grep "INITIAL_FILESYNC_COMPLETED" $FILESYNC_STATUS_FILE_PATH) ]; then
	echo "INITIAL_FILESYNC_FAILED" >> $FILESYNC_STATUS_FILE_PATH
	exit 1
fi

# start unison
unison WORDPRESS_HOME HOME_SITE_LOCAL_STG -auto -batch -times -copythreshold 1000 -prefer WORDPRESS_HOME -repeat watch -ignore 'Path UNISON_EXCLUDED_PATH' -perms 0 -log=false
