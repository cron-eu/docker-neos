#!/usr/bin/env bash
set -e

# Configure Xdebug based on environment variables
#
# XDEBUG_ENABLED set to "1" to enable the extension
# XDEBUG_CONFIG is passed to Xdebug to configure stuff at runtime (see https://xdebug.org/docs/remote)

if [ "${XDEBUG_ENABLED}" = "0" ] || [ "${XDEBUG_ENABLED}" = "off" ] || ( [ -z "${XDEBUG_CONFIG}" ] && [ -z "${XDEBUG_ENABLED}" ] )
then
    sed -i -r 's/^zend_extension/;zend_extension/' "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"
    echo "PHP Xdebug extension disabled."

elif [ "${XDEBUG_CONFIG}" = "0" ] || [ "${XDEBUG_CONFIG}" = "off" ]
then

    # backwards compatibility
    sed -i -r 's/^zend_extension/;zend_extension/' "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"
    echo "PHP Xdebug extension disabled. Please use XDEBUG_ENABLED=0 in future!"

else
    sed -i -r 's/^;zend_extension/zend_extension/' "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"

    echo "PHP Xdebug extension enabled with the following config:"
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
