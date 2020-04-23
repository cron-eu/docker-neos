#!/usr/bin/env bash
set -e

# XDEBUG_CONFIG is either empty (disabled) or contains a list of xdebug settings, separated by semicolon:
#
# i.e.:
#
#   XDEBUG_CONFIG='idekey=PHPSTORM;remote_enable=1'
#
# generates these settings:
#
#   xdebug.idekey=PHPSTORM
#   xdebug.remote_enable=1

if [ -z "${XDEBUG_CONFIG}" ] ||  [ "${XDEBUG_CONFIG}" = "0" ] || [ "${XDEBUG_CONFIG}" = "off" ]
then
    sed -i -r 's/^zend_extension/;zend_extension/' "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"
else
    sed -i -r 's/^;zend_extension/zend_extension/' "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"
    if [ "${XDEBUG_CONFIG}" != "on" ] &&  [ "${XDEBUG_CONFIG}" != "1" ]; then
      IFS=';'
      for d in $XDEBUG_CONFIG ; do echo "xdebug.$d" >> "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"; done
      unset IFS
    fi

    echo "Xdebug enabled with the follwing config:"
    echo "-- 8< --------------------------------------------------"
    cat "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"
    echo "-- 8< --------------------------------------------------"

    # create a wrapper script "php-debug" for starting debugging from the CLI
    cat <<'EOF' > /usr/local/bin/php-debug
#!/usr/bin/env bash
php -d xdebug.remote_autostart=1 "$@"
EOF
    chmod +x /usr/local/bin/php-debug

fi
