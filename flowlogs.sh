#/bin/bash
ELB=$1
ELBLOGGROUP="/aws/appflowlogs/$ELB/elb"
EC2LOGGROUP="/aws/appflowlogs/$ELB/ec2"
ROLE="arn:aws:iam::XXXXXXXXXXXX:role/FlowLogsRole"

ELB_ENIS=$(aws ec2 describe-network-interfaces --filters "Name=description,Values=ELB $ELB" --query 'NetworkInterfaces[*].{ENI:NetworkInterfaceId}' --output text | tr '\n' ' ')
EC2S=$(aws elb describe-load-balancers --load-balancer-name $ELB --query 'LoadBalancerDescriptions[*].Instances[*].{instanceid:InstanceId}' --output text)
EC2_ENIS=$(aws ec2 describe-instances --instance-ids $EC2S --query 'Reservations[*].Instances[*].NetworkInterfaces[*].{iface:NetworkInterfaceId}' --output text | tr '\n' ' ')

echo "ELB ENIs: $ELB_ENIS"
aws ec2 create-flow-logs --resource-type NetworkInterface --resource-ids $ELB_ENIS --traffic-type ALL --log-group-name $ELBLOGGROUP --deliver-logs-permission-arn $ROLE
echo "EC2 ENIs: $EC2_ENIS"
aws ec2 create-flow-logs --resource-type NetworkInterface --resource-ids $EC2_ENIS --traffic-type ALL --log-group-name $EC2LOGGROUP --deliver-logs-permission-arn $ROLE
