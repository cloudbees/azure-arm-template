#!/bin/bash

set -e

#
# Copyright (c) 2016, CloudBees, Inc.
#

#
# Azure ARM setup script to prepare a CJE VM for integration for integration within CJP
#
# usage:
#   setup-master.sh <index_of_master_node> <dns_domain_name> <template_root_url> <subscriptionId>
#

index=$1
size=$2
domain=$3
rooturl=$4
subscription=$5


# Install licensing plugin
mkdir -p /var/lib/jenkins/plugins
curl $rooturl/client-master-marketplace-licensing.hpi -o /var/lib/jenkins/plugins/client-master-marketplace-licensing.hpi
chown -Rf jenkins:jenkins /var/lib/jenkins/


CFG="/var/lib/jenkins/com.cloudbees.opscenter.client.plugin.OperationsCenterRootAction.xml"
# Inject openration center connection details
echo "<?xml version='1.0' encoding='UTF-8'?>
<com.cloudbees.opscenter.client.plugin.OperationsCenterRootAction_-DescriptorImpl>
  <state>CONNECTABLE</state>
  <connectionDetails>----- BEGIN CONNECTION DETAILS -----" > $CFG
echo "{
  \"url\": \"http://$domain\",
  \"id\": \"$index-jenkins-$index%20(built-in)\",
  \"grant\": \"jenkins-$index\"
}" | gzip -f | base64 >> $CFG
echo "----- END CONNECTION DETAILS -----
</connectionDetails>
  <configurable>true</configurable>
  <registered>true</registered>
</com.cloudbees.opscenter.client.plugin.OperationsCenterRootAction_-DescriptorImpl>
" >> $CFG

chown jenkins:jenkins $CFG


# Configure Jenkins root URL
echo "<?xml version='1.0' encoding='UTF-8'?>
<jenkins.model.JenkinsLocationConfiguration>
  <adminAddress>address not configured yet &lt;nobody@nowhere&gt;</adminAddress>
  <jenkinsUrl>http://jenkins-$index-$domain/</jenkinsUrl>
</jenkins.model.JenkinsLocationConfiguration>"                                      \
> /var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml

chown jenkins:jenkins /var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml

echo "Azure Marketplace" > /var/lib/jenkins/.cloudbees-referrer.txt
echo "    size: $size" >> /var/lib/jenkins/.cloudbees-referrer.txt
echo "    subscriptionId: $subscription" >> /var/lib/jenkins/.cloudbees-referrer.txt

/etc/init.d/jenkins restart
