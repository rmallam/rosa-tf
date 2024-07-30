#!/bin/bash

exec 2>&1 1>enable-siem.log

date=`date`
echo "###############################################"
echo "######## $date #########"
echo "###############################################"

rosa login -t ${token}

rosa edit cluster -c ${cluster} --audit-log-arn "${siem_role_arn}" --yes
