#!/bin/sh
set -eu

: "${BOX_ROOT_FOLDER_ID:?BOX_ROOT_FOLDER_ID is required}"
: "${BOX_JWT_CONFIG_PATH:=/run/secrets/box-jwt-config.json}"

test -r "$BOX_JWT_CONFIG_PATH"

mkdir -p /home/boxmount/.box-mount
chown boxmount:boxmount /home/boxmount/.box-mount
mkdir -p /mnt/box

install \
  -o boxmount \
  -g boxmount \
  -m 600 \
  "$BOX_JWT_CONFIG_PATH" \
  /home/boxmount/box-jwt-config.json

printf '%s\n' \
  '{"auth_type":"jwt","jwt_config_path":"/home/boxmount/box-jwt-config.json"}' \
  > /home/boxmount/.box-mount/box-config.json

chown boxmount:boxmount /home/boxmount/.box-mount/box-config.json
chmod 700 /home/boxmount/.box-mount
chmod 600 /home/boxmount/.box-mount/box-config.json

chown boxmount:boxmount-share /mnt/box || true
chmod 2770 /mnt/box || true
setfacl -m g:boxmount-share:rwx -m d:g:boxmount-share:rwx /mnt/box || true

runuser -u boxmount -- \
  env HOME=/home/boxmount \
  box-mount mount "/mnt/box" "$BOX_ROOT_FOLDER_ID"

runuser -u boxmount -- \
  env HOME=/home/boxmount \
  box-mount status

# The review worker is trusted for this demo because it needs the Box JWT.
runuser -u boxmount -- \
  env HOME=/home/boxmount \
  BOX_JWT_CONFIG_PATH=/home/boxmount/box-jwt-config.json \
  python /app/agent.py

runuser -u boxmount -- \
  env HOME=/home/boxmount \
  box-mount unmount "/mnt/box"
