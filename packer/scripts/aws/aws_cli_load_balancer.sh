#!/bin/bash

#aws cli load balancer and auto scaling script

key=packer
subnet_id=
vpc_id=
security_group_id=

AMI_ID=

load_balancer_name=icap-load-balancer
auto_scaling_config_name=icap-config
auto_scaling_group_name=icap-auto-scaling-group
target_group_name=icap-targets

#Deleting existing load balancer
existing_load_balancer=$(aws elbv2 describe-load-balancers --names $load_balancer_name 2<&- )
existing_load_balancer_arn=$(echo $existing_load_balancer | jq -r ".LoadBalancers[0].LoadBalancerArn")
if [ -n  "${existing_load_balancer_arn}" ]; then
    echo "Deleting existing load balancer"
    aws elbv2 delete-load-balancer --load-balancer-arn $existing_load_balancer_arn
fi

#Deleting existing target group balancer
existing_target=$(aws elbv2 describe-target-groups --names $target_group_name 2<&-)
existing_target_arn=$(echo $existing_target | jq -r ".TargetGroups[0].TargetGroupArn")

if [ -n  "${existing_target_arn}" ]; then
    echo "Deleting existing target group balancer"
    aws elbv2 delete-target-group --target-group-arn $existing_target_arn
fi

#Deleting existing Auto_scale Group
existing_auto_scaling_group=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $auto_scaling_group_name 2<&-)
auto_scale_exists=$(echo $existing_auto_scaling_group | jq -r ".AutoScalingGroups" 2<&-)

if [ "${auto_scale_exists}" !=  "[]" ]; then
    echo "Deleting existing auto_scale group"
    aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $auto_scaling_group_name --force-delete
    
    echo "Sleeping for 10 minutes"
    sleep 600
fi

#Deleting existing launch config
existing_auto_config_group=$(aws autoscaling describe-launch-configurations --launch-configuration-name $auto_scaling_config_name 2<&-)
config_exists=$(echo $existing_auto_config_group | jq -r ".LaunchConfigurations" 2<&-)
if [ "${config_exists}" !=  "[]" ]; then
    echo "Deleting existing launch config"
    aws autoscaling delete-launch-configuration --launch-configuration-name $auto_scaling_config_name
fi

#Create load balancer and target group
load_balancer_json=$(aws elbv2 create-load-balancer --name $load_balancer_name --type network --subnets $subnet_id)
target_group_json=$(aws elbv2 create-target-group --name $target_group_name --protocol TCP --port 1345 --vpc-id $vpc_id)

#Extract ARNs
load_balancer_arn=$(echo $load_balancer_json | jq -r ".LoadBalancers[0].LoadBalancerArn")
target_group_arn=$(echo $target_group_json | jq -r ".TargetGroups[0].TargetGroupArn")


#Create Autoscaling Instances
aws autoscaling create-launch-configuration --launch-configuration-name $auto_scaling_config_name --key-name $key --image-id $AMI_ID --security-groups $security_group_id --instance-type t2.large --associate-public-ip-address
aws autoscaling create-auto-scaling-group --auto-scaling-group-name  $auto_scaling_group_name --launch-configuration-name $auto_scaling_config_name --vpc-zone-identifier $subnet_id --tags Key=Name,Value=icap-sm-load-balancer,PropagateAtLaunch=true --target-group-arns  $target_group_arn --max-size 5 --min-size 1 --desired-capacity 3

echo $load_balancer_arn
echo $target_group_arn

#Assosiate LoadBalancer with TargetGroups
aws elbv2 create-listener --load-balancer-arn $load_balancer_arn --protocol TCP --port 1345  --default-actions Type=forward,TargetGroupArn=$target_group_arn

#Assosiate Autoscaling with TargetGroups
aws autoscaling attach-load-balancer-target-groups --auto-scaling-group-name $auto_scaling_group_name --target-group-arns $target_group_arn



