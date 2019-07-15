# AWS scripts
Amazon Web Services scripts and helper functions

## [ec2-cron.sh](https://github.com/ivco/aws/blob/master/ec2-cron.sh)
Do you have one service running on multiple EC2 instances in AWS that needs a cron job? You don't like all instances to run the same cron job...

This is a script that will help you set up cron job for only one EC2 instance in an Auto Scaling Group

It works with resource tagging, adding cron tag to on or off to the instance. Only one EC2 instance per Auto Scaling Group can have the tag: cron = "on" at a time. All others have the tag: cron = "off"

We use aws cli for getting the auto scaling group and the instances in it with LifecycleState = "InService"

Then we check the tag "cron" for all instances in the ASG. If one has the value cron = "on" then we skip setting the cron on the current instnace where this script is executed. If all of them have cron = "off" we set the cron to be run on this instance.

You will need to add 2 policies to the EC2 role:
- AutoScalingReadOnlyAccess (AWS managed policy):
```json{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "autoscaling:Describe*",
            "Resource": "*"
        }
    ]
}
```
- ResourceTagging (Customer policy): 
```json{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ec2:CreateTags"
            ],
            "Resource": "*"
        }
    ]
}
```

We use [jq](https://github.com/stedolan/jq) for processing aws cli results in the bash script. 
