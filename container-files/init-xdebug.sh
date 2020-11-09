#!/usr/bin/env bash
set -e

# XDEBUG_CONFIG is either empty (disabled) or contains a list of xdebug settings, separated by spaces.
# These are used directly by the xdebug module (see https://xdebug.org/docs/remote) and overrides
# the defaults. I.e.:
#   XDEBUG_CONFIG='idekey=PHPSTORM remote_enable=1'

if [ -z "${XDEBUG_CONFIG}" ] ||  [ "${XDEBUG_CONFIG}" = "0" ] || [ "${XDEBUG_CONFIG}" = "off" ]
then
    sed -i -r 's/^zend_extension/;zend_extension/' "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"
else
    sed -i -r 's/^;zend_extension/zend_extension/' "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"

    echo "Xdebug enabled with the following config:"
    echo "-- 8< --------------------------------------------------"
    cat "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"
    echo "-- 8< --------------------------------------------------"
    echo "Overrides in XDEBUG_CONFIG: ${XDEBUG_CONFIG}"
    echo ""

    # create a wrapper script "php-debug" for starting debugging from the CLI
    cat <<'EOF' > /usr/local/bin/php-debug
#!/usr/bin/env bash
php -d xdebug.remote_autostart=1 "$@"
EOF
    chmod +x /usr/local/bin/php-debug

fi
