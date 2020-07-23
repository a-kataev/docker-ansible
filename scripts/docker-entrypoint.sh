#!/bin/sh

test ! -f /entrypoint.sh && ((>&2 echo "file /entrypoint.sh not found") && exit 1)
chown -R app:app /app /entrypoint.d
find /entrypoint.d/ -mindepth 1 -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null
exec su-exec app /entrypoint.sh "${@}"
