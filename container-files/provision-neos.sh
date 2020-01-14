#!/usr/bin/env bash
set -ex

function update_settings_yaml() {
  local settings_file=$1

  cd /data/www-provisioned
  create_settings_yaml $settings_file
}

# set/update docker env settings (required for running the flow command in CLI mode)
function update_global_env_vars() {
  cat <<EOF >/etc/profile.d/docker_env.sh
export DB_DATABASE="${DB_DATABASE}"
export DB_USER="${DB_USER}"
export DB_PASS="${DB_PASS}"
export DB_HOST="${DB_HOST}"
EOF
  chmod +x /etc/profile.d/docker_env.sh
}

function update_neos_settings() {
  if [ -z "${FLOW_CONTEXT}" ]; then
	  update_settings_yaml Configuration/Settings.yaml
  else
	  update_settings_yaml Configuration/${FLOW_CONTEXT}/Settings.yaml
    if [ "${FLOW_CONTEXT}" = "Development/Behat" ]; then
	    update_settings_yaml Configuration/Testing/Behat/Settings.yaml
    fi
  fi
}

function create_settings_yaml() {
  local settings_file=$1
  mkdir -p /data/www-provisioned/$(dirname $settings_file)
  if [ ! -f /data/www-provisioned/$settings_file ] ; then
    cp /Settings.yaml /data/www-provisioned/$settings_file
  fi
}

update_global_env_vars

# Provision conainer at first run
if [ -f /data/www/composer.json ] || [ -f /data/www-provisioned/composer.json ] || [ -z "$REPOSITORY_URL" -a ! -f "/src/composer.json" ]
then
	echo "Do nothing, initial provisioning done"

	# Update DB Settings to keep them in sync with the docker ENV vars
  update_neos_settings
else
  # Make sure to init xdebug, not to slow-down composer
  /init-xdebug.sh

  # Layout default directory structure
  mkdir -p /data/www-provisioned
  mkdir -p /data/logs
  mkdir -p /data/tmp/nginx

  ###
  # Install into /data/www
  ###
  cd /data/www-provisioned

  if [ "${REPOSITORY_URL}" ] ; then
    git clone -b $VERSION $REPOSITORY_URL .
  else
    rsync -r --exclude node_modules --exclude .git --exclude /Data /src/ .
  fi

  composer install $COMPOSER_INSTALL_PARAMS
  update_neos_settings

  # Set permissions
  chown www-data:www-data -R /tmp/
	chown www-data:www-data -R /data/
	chmod g+rwx -R /data/*

	# Set ssh permissions
	if [ -z "/data/.ssh/authorized_keys" ]
		then
			chown www-data:www-data -R /data/.ssh
			chmod 700 /data/.ssh
			chmod 600 /data/.ssh/authorized_keys
	fi
fi
