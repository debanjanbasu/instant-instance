#!/usr/bin/env pwsh

$InstanceId=(Invoke-WebRequest -Uri 'http://169.254.169.254/latest/meta-data/instance-id').Content

$ImageId = aws ec2 create-image `
    --instance-id $InstanceId `
    --name "cloud-gaming-ami-$(Get-Date -format 'dd-MM-yyyy-hh-mm-ss-tt')" `
    --description="cloud-gaming-ami-$(Get-Date -format 'dd-MM-yyyy-hh-mm-ss-tt')" `
    --no-reboot `
    --query ImageId `
    --output text `
    --tag-specifications "ResourceType=image,Tags=[{Key=Name,Value=cloud-gaming-ami-$(Get-Date -format 'dd-MM-yyyy-hh-mm-ss-tt')}]" "ResourceType=snapshot,Tags=[{Key=Name,Value=cloud-gaming-snapshot-$(Get-Date -format 'dd-MM-yyyy-hh-mm-ss-tt')}]"

# Wait for the image to be available
aws ec2 wait image-available `
    --image-ids $ImageId

# Store the id in ssm parameter store
aws ssm put-parameter `
    --name "cloud-gaming-latest-ami-id" `
    --type "String" `
    --value $ImageId `
    --overwrite

# Cleanup the previous AMIs, and Snapshots
aws ec2 describe-images --filters "Name=tag:Name,Values=cloud-gaming-ami-*" --query 'reverse(sort_by(Images, &CreationDate))[1:].ImageId' --output json | ConvertFrom-Json | ForEach-Object { aws ec2 deregister-image --image-id $_ }
aws ec2 describe-snapshots --filters "Name=tag:Name,Values=cloud-gaming-snapshot-*" --query 'reverse(sort_by(Snapshots, &StartTime))[1:].SnapshotId' --output text | %{ $_.split("`t"); } | ForEach-Object { aws ec2 delete-snapshot --snapshot-id $_ }

# Terminate / Kill the instance
aws ec2 terminate-instances --instance-ids $InstanceId
