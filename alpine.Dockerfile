ARG PYTHON_VERSION=3.7

FROM python:${PYTHON_VERSION}-alpine

LABEL maintainer="Alex Kataev <dlyavsehpisem@gmail.com>"

ARG ANSIBLE_VERSION=2.9.17

ENV ANSIBLE_VERSION=${ANSIBLE_VERSION}

COPY requirements.txt /tmp

RUN set -x && \
  apk add --no-cache --virtual .build-deps \
    bzip2-dev coreutils dpkg-dev dpkg expat-dev findutils gcc gdbm-dev libc-dev libffi-dev \
    libnsl-dev libtirpc-dev linux-headers make ncurses-dev openssl-dev pax-utils readline-dev \
    sqlite-dev tcl-dev tk tk-dev util-linux-dev xz-dev zlib-dev && \
  pip --no-cache-dir --disable-pip-version-check install ansible==${ANSIBLE_VERSION} && \
  sed -i '/^ansible\([^-]\)/d' /tmp/requirements.txt && \
  ((ansible --version | grep -oEq 'ansible 2.[3-9].' && python --version | grep -oEq '3.[6-7]') || \
    sed -i '/^mitogen/d' /tmp/requirements.txt) && \
  pip --no-cache-dir --disable-pip-version-check install -r /tmp/requirements.txt && \
  find /usr/local -type f -executable -not \( -name '*tkinter*' \) \
    -exec scanelf --needed --nobanner --format '%n#p' '{}' ';' | tr ',' '\n' | sort -u | \
    awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' | \
    xargs -rt apk add --no-cache --virtual .python-rundeps && \
  apk del --no-cache .build-deps && \
  find /usr/local -not -path '*/ansible/*' -depth \( \
      \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \
      \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name '*.a' \) \) \
    \) -exec rm -rf '{}' + && \
  apk add --no-cache su-exec openssh-client curl jq tree zip git rsync && \
  rm -rf /root/.cache /tmp/* && \
  adduser -h /app -s /bin/sh -D -u 1000 app && \
  mkdir /app/.ansible && \
  rm -rf /root/.ansible && \
  ln -s /app/.ansible /root/.ansible && \
  touch /app/.ansible/ansible.cfg && \
  ln -s /app/.ansible/ansible.cfg /app/.ansible.cfg && \
  ln -s /app/.ansible/ansible.cfg /root/.ansible.cfg && \
  chown -R app:app /app && \
  mkdir /entrypoint.d

WORKDIR /app

COPY scripts/docker-entrypoint.sh /
COPY scripts/entrypoint.sh /

RUN set -x && \
  chmod +x /docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["sh"]
