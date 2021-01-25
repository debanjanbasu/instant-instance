resource "aws_ssm_document" "create_new_image_delete_old" {
  name          = "image-reimage"
  document_type = "Automation"

  content = <<DOC
  {
  "description": "Creates a new Amazon Machine Image (AMI) from an Amazon EC2 instance, deletes the old AMI, and stores the new AMI in SSM",
  "schemaVersion": "0.3",
  "assumeRole": "{{ AutomationAssumeRole }}",
  "parameters": {
    "InstanceId": {
      "type": "String",
      "description": "(Required) The ID of the Amazon EC2 instance."
    },
    "NoReboot": {
      "type": "Boolean",
      "description": "(Optional) Do not reboot the instance before creating the image.",
      "default": false
    },
    "AutomationAssumeRole": {
      "type": "String",
      "description": "(Optional) The ARN of the role that allows Automation to perform the actions on your behalf. ",
      "default": ""
    },
    "ToDeleteImageId": {
      "type": "String",
      "description": "(Required) The ID of the Amazon Machine Image (AMI) to delete.",
      "default": "{{ssm:${var.ssm_ami_parameter_name}}}"
    }
  },
  "mainSteps": [
    {
      "name": "createImage",
      "action": "aws:createImage",
      "onFailure": "Abort",
      "inputs": {
        "InstanceId": "{{ InstanceId }}",
        "ImageName": "{{ InstanceId }}-{{global:DATE_TIME}}-{{automation:EXECUTION_ID}}",
        "ImageDescription": "${var.instance_name}-ami-{{global:DATE_TIME}}",
        "NoReboot": "{{ NoReboot }}"
      },
      "nextStep": "stopInstances"
    },
    {
      "name": "stopInstances",
      "action": "aws:changeInstanceState",
      "onFailure": "step:deleteImage",
      "inputs": {
        "InstanceIds": ["{{ InstanceId }}"],
        "DesiredState": "terminated"
      },
      "nextStep": "deleteImage"
    },
    {
      "name": "deleteImage",
      "action": "aws:deleteImage",
      "onFailure": "step:storeAMIId",
      "inputs": {
        "ImageId": "{{ ToDeleteImageId }}"
      },
      "nextStep": "storeAMIId"
    },
    {
      "name": "storeAMIId",
      "action": "aws:executeAwsApi",
      "onFailure": "Abort",
      "inputs": {
        "Service": "ssm",
        "Api": "PutParameter",
        "Name": "${var.ssm_ami_parameter_name}",
        "Overwrite": true,
        "Value": "{{ createImage.ImageId }}"
      }
    }
  ],
  "outputs": [
    "createImage.ImageId"
  ]}
  DOC

  tags = merge(var.additional_tags, {
    Name = "${var.ssm_ami_parameter_name}-ssm-param"
  })
}
