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
test -n "${SSH_AGENT_PID}" -a -S "${SSH_AUTH_SOCK}" && "${@}"
