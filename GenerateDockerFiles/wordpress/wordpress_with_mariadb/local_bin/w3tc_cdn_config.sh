#Verify CDN endpoint is live

response=$(curl --write-out '%{http_code}' --silent --output /dev/null {https://$CDN_ENDPOINT})
if [[ "$cdn_type" == "BLOB_AFD" ]]; then
    response=$(curl --write-out '%{http_code}' --silent --output /dev/null {https://$AFD_ENDPOINT})
fi

cdn_type="$1"

if [[ $response == "200" ]]; then
    #Configure CDN settings 
    if [[ "$cdn_type" == "BLOB_CDN" ]] && [[ $CDN_ENDPOINT ]] &&[ ! $(grep "BLOB_CDN_CONFIGURATION_COMPLETE" $WORDPRESS_LOCK_FILE) ] \
    && wp w3-total-cache option set cdn.azure.cname $CDN_ENDPOINT --type=array --path=$WORDPRESS_HOME --allow-root \
    && wp w3-total-cache option set cdn.includes.enable true --type=boolean --path=$WORDPRESS_HOME --allow-root \
    && wp w3-total-cache option set cdn.theme.enable true --type=boolean --path=$WORDPRESS_HOME --allow-root \
    && wp w3-total-cache option set cdn.custom.enable true --type=boolean --path=$WORDPRESS_HOME --allow-root; then
        echo "BLOB_CDN_CONFIGURATION_COMPLETE" >> $WORDPRESS_LOCK_FILE
        service atd stop
        redis-cli flushall
    elif [[ "$cdn_type" == "CDN" ]] && [[ $CDN_ENDPOINT ]] &&[ ! $(grep "CDN_CONFIGURATION_COMPLETE" $WORDPRESS_LOCK_FILE) ] \
    && wp w3-total-cache option set cdn.enabled true --type=boolean --path=$WORDPRESS_HOME --allow-root \
    && wp w3-total-cache option set cdn.engine "mirror" --path=$WORDPRESS_HOME --allow-root \
    && wp w3-total-cache option set cdn.mirror.domain $CDN_ENDPOINT --type=array --path=$WORDPRESS_HOME --allow-root; then
        echo "CDN_CONFIGURATION_COMPLETE" >> $WORDPRESS_LOCK_FILE
        service atd stop
        redis-cli flushall
    if [[ "$cdn_type" == "BLOB_AFD" ]] && [[ $AFD_ENDPOINT ]] && [ ! $(grep "BLOB_AFD_CONFIGURATION_COMPLETE" $WORDPRESS_LOCK_FILE) ] \
    && wp w3-total-cache option set cdn.azure.cname $AFD_ENDPOINT --type=array --path=$WORDPRESS_HOME --allow-root \
    && wp w3-total-cache option set cdn.includes.enable true --type=boolean --path=$WORDPRESS_HOME --allow-root \
    && wp w3-total-cache option set cdn.theme.enable true --type=boolean --path=$WORDPRESS_HOME --allow-root \
    && wp w3-total-cache option set cdn.custom.enable true --type=boolean --path=$WORDPRESS_HOME --allow-root; then
        if [ $(grep "# Update site_url value here." $WORDPRESS_HOME/wp-config.php) ]; then
            sed -i "# Update site_url value here./c \$site_url = (getenv('AFD_ENDPOINT')) ? getenv('AFD_ENDPOINT') : \$_SERVER['HTTP_HOST'];" $WORDPRESS_HOME/wp-config.php
        fi
        echo "BLOB_AFD_CONFIGURATION_COMPLETE" >> $WORDPRESS_LOCK_FILE
        service atd stop
        redis-cli flushall
    else
        service atd start
        echo "bash /usr/local/bin/w3tc_cdn_config.sh $cdn_type" | at now +5 minutes
    fi
else
    service atd start
    echo "bash /usr/local/bin/w3tc_cdn_config.sh $cdn_type" | at now +5 minutes
fi
