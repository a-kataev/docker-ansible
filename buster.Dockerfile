ARG PYTHON_VERSION=3.7

FROM python:${PYTHON_VERSION}-slim

RUN set -x && \
  apt-get update && \
  apt-get install -y --no-install-recommends curl gcc libc-dev && \
  curl -so /usr/src/su-exec.c https://raw.githubusercontent.com/ncopa/su-exec/master/su-exec.c && \
  gcc -Wall /usr/src/su-exec.c -o /usr/local/bin/su-exec && \
  apt-get purge -y --auto-remove curl gcc libc-dev && \
  rm -rf /var/lib/apt/lists/*

FROM python:${PYTHON_VERSION}-slim

LABEL maintainer="Alex Kataev <dlyavsehpisem@gmail.com>"

ARG ANSIBLE_VERSION=2.8.14

ENV ANSIBLE_VERSION=${ANSIBLE_VERSION}

COPY requirements.txt /tmp

RUN set -x && \
  apt-get update && \
  apt-get install -y --no-install-recommends openssh-client curl jq tree unzip procps net-tools vim-tiny less && \
  pip --no-cache-dir --disable-pip-version-check install ansible==${ANSIBLE_VERSION} && \
  sed -i '/^ansible\([^-]\)/d' /tmp/requirements.txt && \
  pip --no-cache-dir --disable-pip-version-check install -r /tmp/requirements.txt && \
  find /usr/local -not -path '*/ansible/*' -depth \( \
      \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \
      \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name '*.a' \) \) \
    \) -exec rm -rf '{}' + && \
  rm -rf /root/.cache /tmp/* /var/lib/apt/lists/* && \
  useradd -m -d /app -s /bin/sh -u 1000 app && \
  mkdir /app/.ansible && \
  touch /app/.ansible/ansible.cfg && \
  ln -s /app/.ansible/ansible.cfg /app/.ansible.cfg && \
  chown -R app:app /app && \
  mkdir /entrypoint.d

COPY --from=0 /usr/local/bin/su-exec /usr/local/bin/su-exec

WORKDIR /app

COPY scripts/docker-entrypoint.sh /
COPY scripts/entrypoint.sh /

RUN set -x && \
  chmod +x /docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["sh"]
