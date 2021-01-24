#!/usr/bin/env pwsh

$InstanceId=(Invoke-WebRequest -Uri 'http://169.254.169.254/latest/meta-data/instance-id').Content

# Run the automation job
aws ssm start-automation-execution --document-name "image-reimage" `
    --parameters InstanceId=$InstanceId
    