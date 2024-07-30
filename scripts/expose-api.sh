#!/bin/bash

exec 2>&1 1>expose-api.log

date=`date`
echo "###############################################"
echo "######## $date #########"
echo "###############################################"

read -r VPCE_ID VPC_ID <<< $(aws ec2 describe-vpc-endpoints --filters "Name=tag:api.openshift.com/id,Values=$(rosa describe cluster -c ${cluster} -o yaml | grep '^id: ' | cut -d' ' -f2)" --query 'VpcEndpoints[].[VpcEndpointId,VpcId]' --output text)
export SG_ID=$(aws ec2 create-security-group --description "Granting API access to ${cluster} from outside of VPC" --group-name "${cluster}-api-sg" --vpc-id $VPC_ID --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --ip-permissions FromPort=443,ToPort=443,IpProtocol=tcp,IpRanges=[{CidrIp=0.0.0.0/0}]
aws ec2 modify-vpc-endpoint --vpc-endpoint-id $VPCE_ID --add-security-group-ids $SG_ID
