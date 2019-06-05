#!/usr/bin/env bash

function behat_configure_yml_files() {
  local behat_vhost=$@

  cd /data/www-provisioned

  for f in Packages/*/*/Tests/Behavior/behat.yml.dist; do
    target_file=${f/.dist/}
    if [ ! -f $target_file ]; then
      cp $f $target_file
    fi
    # Find all base_url: setting (might be commented out) and replace it with $behat_vhost
    sed -i -r "s/(#\s?)?base_url:.+/base_url: http:\/\/${behat_vhost}\//g" $target_file
    echo "$target_file configured for Behat testing."
  done
}

behat_configure_yml_files "$1"
