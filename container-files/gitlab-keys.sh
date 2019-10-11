#!/usr/bin/env bash

#
# Source: https://github.com/rtlong, https://gist.github.com/rtlong/6790049
# Usage: /gitlab-keys.sh | bash -s <gitlab server URL> <gitlab username>
#
IFS="$(printf '\n\t')"

GITLAB_URL="$1"
user="$2"

if [ -z "$GITLAB_URL" ]; then
  echo "ERROR: \$GITLAB_URL ENV var not set. See the documentation."
  exit 1
fi

api_response=$(curl -sSLi ${GITLAB_URL}/${user}.keys)
keys=$(echo "$api_response" | grep -o -E 'ssh-\w+\s+[^\"]+')

if [ -z "$keys" ]; then
  echo "WARNING: ${GITLAB_URL} doesn't have any keys for '$user' user."
else
  echo "Importing $user's ${GITLAB_URL} pub key(s) to `whoami` account..."

  [ -d ~/.ssh ] || mkdir ~/.ssh
  [ -f ~/.ssh/authorized_keys ] || touch ~/.ssh/authorized_keys

  for key in $keys; do
    echo "Imported ${GITLAB_URL} $user key: $key"
    grep -q "$key" ~/.ssh/authorized_keys || echo "$key ${user}@${GITLAB_URL}" >> ~/.ssh/authorized_keys
  done
fi
