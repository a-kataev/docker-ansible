# docker-ansible

My docker images for [ansible](https://github.com/ansible/ansible).

## Key features

### Build different versions `ansible` and `python`

This images are based on official [python](https://hub.docker.com/_/python) images (`apline` and `buster-slim` (in testing)).

To build with docker use `--build-arg` and set `PYTHON_VERSION` and `ANSIBLE_VERSION`.

### Support `requirements.txt` when building images

Package `ansible` is ignored always.

Package `mitogen` is ignored if versions `ansible` or `python` are not supported ([link](https://mitogen.networkgenomics.com/ansible_detailed.html#noteworthy-differences)).

### Execute `entrypoint` as non-root user

By default, all processes in `entrypoint` are executed as user `app` (`1000`).

To execute as root use environment `RUN_AS_ROOT`, for example `RUN_AS_ROOT=true`.

### Single working directory `/app`

For ansible, working directory is `/app/.ansible` and the main config `/app/.ansible/ansible.cfg` (symlink to `/app/.ansible.cfg`).

This applies equally to the user `app` and` root`. For user root symlinks exist in `/root`.

### Background process `ssh-agent`

Starting `entrypoint` the background process of `ssh-agent` runs.

You can change the environment `SSH_AUTH_SOCK`, `/app/.ssh-agent.sock` is by default.

### Running additional scripts at startup

Use `.sh` files in directory `/entrypoint.d`.

All scripts are executed as `root` before running `entrypoint`.

## Usage

Clone repository

```shell
$ git clone git@github.com:a-kataev/docker-ansible.git
$ cd docker-ansible
```

Edit `requirements.txt`

```shell
$ echo "pyjwt" >> requirements.txt
```

Build a new docker image

```shell
$ docker build \
  --build-arg PYTHON_VERSION=3.8 \
  --build-arg ANSIBLE_VERSION=2.9.13 \
  -f buster.Dockerfile \
  -t ansible \
  .
```

Create a new script

```shell
$ mkdir -p scripts/entrypoint.d
$ cat <<EOF > scripts/entrypoint.d/00-generate-ssh-key.sh
#!/bin/sh
test -f /app/.ssh/new && exit
ssh-keygen -q -N '' -C '' -f /app/.ssh/new
ssh-add /app/.ssh/new
ssh-add -L
EOF
```

Create a simple playbook, hosts file and config

```shell
$ mkdir ansible
$ cat <<EOF > ansible/playbook.yml
---
- hosts: localhost
  tasks:
    - debug:
        var: ansible_python_version
EOF
$ cat <<EOF > ansible/hosts
localhost ansible_connection=local ansible_python_interpreter=/usr/local/bin/python
EOF
$ cat <<EOF > ansible/ansible.cfg
[defaults]
inventory = ~/.ansible/hosts
EOF
```

Run a container from new image

```shell
$ docker run --name ansible --rm \
  -v "$(pwd)/scripts/entrypoint.d:/entrypoint.d" \
  -v "$(pwd)/ssh:/app/.ssh" \
  -v "$(pwd)/ansible:/app/.ansible" \
  -it ansible
start ssh-agent
launching /entrypoint.d/00-generate-ssh-key.sh
Identity added: /app/.ssh/new (/app/.ssh/new)
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBcHpys/Rs1JehOQ5oI2O6J/5N6ic9izhc8bbZ5de2/dNlXhhbP75l3X
xlhKIPkFjAL8f85Kq0xdUYDP5bZ9DNMYOQiGyBB+UFL7E+55mbu1ebIDJvvtpTe1KGToXI2NYjUodSm/eNk7K4L936ZqWg
BICKmHm/zYZ5pv2yVdqlWuC5Tu4nLvCYVfV+QoYi9vyQ4sfpKkqVv/impHYsCbUIjZwvM9DdrEZEzDVRzgnZ9MFRYHV/p5
KGZ5w7bxTtU3ciWPDU5AQJb1QJlXHHMmRjV4P4a7XZF4Dy7wbXG4xFJyseZVtOP
AxxlXK6ACh+p+/AZQxf69InYh8mk8mVpQiX /app/.ssh/new
$ ansible --version
ansible 2.9.13
  config file = /app/.ansible.cfg
  configured module search path = ['/app/.ansible/plugins/modules', '/usr/share/ansible/plugin
s/modules']
  ansible python module location = /usr/local/lib/python3.8/site-packages/ansible
  executable location = /usr/local/bin/ansible
  python version = 3.8.5 (default, Sep 10 2020, 16:58:22) [GCC 8.3.0]
$ ansible-playbook .ansible/playbook.yml

PLAY [localhost] *****************************************************************************

TASK [Gathering Facts] ***********************************************************************
ok: [localhost]

TASK [debug] *********************************************************************************
ok: [localhost] => {
    "ansible_python_version": "3.8.5"
}

PLAY RECAP ***********************************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    re
scued=0    ignored=0

$ exit
```
