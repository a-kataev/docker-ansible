#!/bin/sh

SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-/app/.ssh-agent.sock}

trap stop EXIT

stop() {
  local code="${?}"
  echo "stop ssh-agent"
  /usr/bin/ssh-agent -s -k >/dev/null 2>&1
  test -S "${SSH_AUTH_SOCK}" && rm -rf "${SSH_AUTH_SOCK}"
  echo "exit code ${code}"
  exit "${code}"
}

test -S "${SSH_AUTH_SOCK}" && rm -rf "${SSH_AUTH_SOCK}"
echo "start ssh-agent"
eval $(/usr/bin/ssh-agent -s -a "${SSH_AUTH_SOCK}" 2>&1) >/dev/null 2>&1

find /entrypoint.d/ -mindepth 1 -maxdepth 1 -type f -name '*.sh' -print 2>/dev/null | \
  sort -n | while read -r f; do
  echo "launching ${f}"
  ${f}
done

test -n "${SSH_AGENT_PID}" -a -S "${SSH_AUTH_SOCK}" && "${@}"
