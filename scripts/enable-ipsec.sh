#!/bin/bash

exec 2>&1 1>enable-ipsec.log

date=`date`
echo "###############################################"
echo "######## $date #########"
echo "###############################################"

#retrieve secret value
sleep 20
url=`aws secretsmanager get-secret-value  --secret-id $secret --query SecretString --output text|jq -r ."url"|xargs`
pw=`aws secretsmanager get-secret-value  --secret-id $secret --query SecretString --output text|jq -r ."password"|xargs`
user=`aws secretsmanager get-secret-value  --secret-id $secret --query SecretString --output text|jq -r ."user"|xargs`
echo "$url"
echo "$pw"
echo "$user"
if [ $? -ne 0 ]
then
  echo "Failed to get AWS secret."
  exit 1
else
  echo "Retrieved aws secret"
fi
# log into cluster
i=0
login="oc login $url --username $user --password $pw"
while [ true ]
do
  $login
  if [ $? -eq 0 ]
    then
      break
  fi
  ((i++))
  if [[ "$i" == '5' ]]
    then
      echo "Number $i!"
      exit 1
  fi
  echo "cluster login not ready sleeping 30"
  sleep 30
done

oc patch networks.operator.openshift.io cluster --type=merge -p '{ "spec":{ "defaultNetwork":{ "ovnKubernetesConfig":{ "ipsecConfig":{ "mode": "full" }}}}}'
sleep 120
for pods in  `oc get pods -n openshift-ovn-kubernetes -l=app=ovnkube-node|grep -v NAME|awk '{print $1}'`
do
  echo $pods
  oc -n openshift-ovn-kubernetes -c ovn-controller rsh $pods ovn-nbctl --no-leader-only get nb_global . ipsec
done