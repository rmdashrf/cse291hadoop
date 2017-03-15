#!/bin/bash

echo Starting hadoop
set -e


# Setup ssh
mkdir -p /root/.ssh
cat /etc/ssh/insecure_keypair.pub >> /root/.ssh/authorized_keys
cp /etc/ssh/insecure_keypair /root/.ssh/id_rsa
cp /etc/ssh/insecure_keypair.pub /root/.ssh/id_rsa.pub

chmod -R og= /root/.ssh

mkdir -p /var/run/sshd
mkdir -p /tmp/.docker_generated/supervisord/

# Setup hadoop cluster
/clustersetup.py $@

# Check if i am master.
if [ -f /tmp/i_am_master ]; then
    bash /tmp/i_am_master
fi

exec supervisord --nodaemon --logfile /tmp/supervisord.log -c /supervisord.conf
