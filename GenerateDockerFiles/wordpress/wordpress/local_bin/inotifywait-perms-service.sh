#!/bin/bash
#trap "kill -- -$$" EXIT
inotifywait -mrq -e CREATE -e MOVED_TO -e CLOSE_WRITE -t -1 --format %w%f "$HOME_SITE_LOCAL_STG" --exclude "^$HOME_SITE_LOCAL_STG/UNISON_EXCLUDED_PATH/"  | while read FILE
do
        chown nginx:nginx $FILE
        chmod 777 $FILE
done