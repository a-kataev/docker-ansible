#!/bin/sh

test ! -f /entrypoint.sh && ((>&2 echo "file /entrypoint.sh not found") && exit 1)
chown -R app:app /app
exec su-exec app /entrypoint.sh "${@}"
