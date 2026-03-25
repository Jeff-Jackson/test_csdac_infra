#!/bin/bash
set -o xtrace
sudo yum update -y
sudo yum install -y dracut-fips
sudo dracut -f
sudo /sbin/grubby --update-kernel=ALL --args="fips=1"
/etc/eks/bootstrap.sh ${ClusterName}


useradd -m svc_ansible
echo "svc_ansible ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

mkdir -p /home/svc_ansible/.ssh
chmod 700 /home/svc_ansible/.ssh
touch /home/svc_ansible/.ssh/authorized_keys
chmod 600 /home/svc_ansible/.ssh/authorized_keys
chown -R svc_ansible:svc_ansible /home/svc_ansible/.ssh
echo "${AnsiblePublicKey}" >> /home/svc_ansible/.ssh/authorized_keys

aws s3 cp s3://csdac-us-gov-west-1-installs-test-scripts/ud-scripts/ud-al2-join-ad-imdsv2.sh /tmp/ud-al2-join-ad-imdsv2.sh && \
aws s3 cp s3://csdac-us-gov-west-1-installs-test-scripts/ud-scripts/ud-splunk-agent-start.sh /tmp/ud-splunk-agent-start.sh && \
aws s3 cp s3://csdac-us-gov-west-1-installs-test-scripts/ud-scripts/ud-tenable-agent-start-rhel.sh /tmp/ud-tenable-agent-start-rhel.sh && \
aws s3 cp s3://csdac-us-gov-west-1-installs-test-scripts/ud-scripts/ud-trend-dsm-agent-start.sh /tmp/ud-trend-dsm-agent-start.sh

chmod +x /tmp/ud*

/tmp/ud-al2-join-ad-imdsv2.sh
/tmp/ud-splunk-agent-start.sh
/tmp/ud-tenable-agent-start-rhel.sh
/tmp/ud-trend-dsm-agent-start.sh

sudo reboot
