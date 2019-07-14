#!/bin/bash

# Script to set cron job task for only one EC2 instance in Auto Scaling Group

# Configure your bucket name and cron file name which needs to be fetched from S3 bucket and put on the server's crontab
bucketName="your-s3-bucket-name"
cronFile="cron.sh"

# Helper variable that we set to 1 if we have one EC2 instances with tag name: cron = on
doWeHaveCronInstance=0

# Get the ID of the current instance where this script is executed
instanceID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Get the Auto Scaling Group ID where this instance is part of
asg=$(aws autoscaling describe-auto-scaling-instances --region eu-central-1 --instance-ids $instanceID | grep AutoScalingGroupName|awk -F\" '{print $4}')

# Get all instances in the Auto Scaling Group with LifecycleState = InService
instances=$(aws autoscaling describe-auto-scaling-groups --region eu-central-1 --auto-scaling-group-names $asg | jq '.AutoScalingGroups[0].Instances[] | select(.LifecycleState=="InService")' | jq -r .InstanceId)

# Iterate through all instances and check if we have a tag with name "cron" and its value is "on" or "off"
for instance in $instances
do
  cron=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$instance" --region eu-central-1 | jq '.Tags[] | select(.Key=="cron")' | jq -r .Value)
  if [ "$cron" == "on" ]; then
    doWeHaveCronInstance=1
  fi
done

# If we still don't have EC2 instances with LifecycleState = InService that have active cron, we set up the cron on this instance
if [ $doWeHaveCronInstance -eq 0 ]; then
  # We set up cron on this instance and we add the tag cron = on
  # We copy a cron job script from S3 bucket
  aws s3 cp s3://$bucketName/$cronFile $cronFile
  chmod +x $cronFile
  location=$(pwd)
  # Set up cron to execute every 5 minutes in crontab of the current running user
  (crontab -l 2>/dev/null; echo "*/5 * * * * /bin/bash $location/$cronFile") | crontab -
  # Set the tag cron = on for the instance
  aws ec2 create-tags --resources "$instanceID" --tags Key="cron",Value="on" --region eu-central-1
else
  # We only tag instance to off
  aws ec2 create-tags --resources "$instanceID" --tags Key="cron",Value="off" --region eu-central-1
fi
