data "aws_ami" "windows_ami" {
  most_recent = true
  owners      = ["amazon"]

  # Get the latest windows server 2019 ami
  filter {
    name   = "name"
    values = ["EC2LaunchV2_Preview-Windows_Server-2019-English-Full-Base*"]
  }
}

data "external" "local_ip" {
  # curl should (hopefully) be available everywhere
  program = ["curl", "https://api.ipify.org?format=json"]
}

resource "random_password" "password" {
  length  = 32
  special = true
}

resource "aws_ssm_parameter" "password" {
  name  = "${var.instance_name}-administrator-password"
  type  = "SecureString"
  value = random_password.password.result

  tags = merge(var.additional_tags, {
    Name = "${var.instance_name}-password"
  })
}

resource "aws_ssm_parameter" "cloud_gaming_latest_ami_id" {
  name = "${var.instance_name}-latest-ami-id"
  type = "String"
  # The value is populated from within the instance - once initialized
  value = (length(var.custom_ami) > 0) ? var.custom_ami : data.aws_ami.windows_ami.image_id

  tags = merge(var.additional_tags, {
    Name = "${var.instance_name}-latest-ami-id"
  })
}

resource "aws_security_group" "default" {
  name   = "${var.instance_name}-sg"
  vpc_id = var.vpc_id

  tags = merge(var.additional_tags, {
    Name = "${var.instance_name}-sg"
  })
}

# Allow rdp connections from the local ip
resource "aws_security_group_rule" "rdp_ingress" {
  type              = "ingress"
  description       = "Allow rdp connections (port 3389)"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["${data.external.local_ip.result.ip}/32"]
  security_group_id = aws_security_group.default.id
}

# Allow vnc connections from the local ip
resource "aws_security_group_rule" "vnc_ingress" {
  type              = "ingress"
  description       = "Allow vnc connections (port 5900)"
  from_port         = 5900
  to_port           = 5900
  protocol          = "tcp"
  cidr_blocks       = ["${data.external.local_ip.result.ip}/32"]
  security_group_id = aws_security_group.default.id
}


# Allow outbound connection to everywhere
resource "aws_security_group_rule" "default" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}

resource "aws_iam_role" "windows_instance_role" {
  name               = "${var.instance_name}-instance-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(var.additional_tags, {
    Name = "${var.instance_name}-instance-role"
  })
}

data "aws_iam_policy" "full_s3_policy_for_game_store" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "aws_iam_policy" "ec2_full_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

data "aws_iam_policy" "ssm_full_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "full_s3_policy_for_game_store_attachment" {
  role       = aws_iam_role.windows_instance_role.name
  policy_arn = data.aws_iam_policy.full_s3_policy_for_game_store.arn
}

resource "aws_iam_role_policy_attachment" "ec2_full_policy_attachment" {
  role       = aws_iam_role.windows_instance_role.name
  policy_arn = data.aws_iam_policy.ec2_full_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm_full_policy_attachment" {
  role       = aws_iam_role.windows_instance_role.name
  policy_arn = data.aws_iam_policy.ssm_full_policy.arn
}

resource "aws_iam_instance_profile" "windows_instance_profile" {
  name = "${var.instance_name}-instance-profile"
  role = aws_iam_role.windows_instance_role.name
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = var.vpc_id
}

resource "random_shuffle" "subnet_id" {
  input        = data.aws_subnet_ids.subnet_ids.ids
  result_count = 1
}

data "aws_region" "current" {}

resource "aws_spot_instance_request" "windows_instance" {
  instance_type   = var.instance_type
  spot_price      = var.spot_max_price
  ami             = (length(var.custom_ami) > 0) ? var.custom_ami : data.aws_ami.windows_ami.image_id
  security_groups = [aws_security_group.default.id]
  user_data = var.skip_install ? "" : templatefile("${path.module}/templates/user_data.tpl", {
    password_ssm_parameter = aws_ssm_parameter.password.name,
    var = {
      instance_type               = var.instance_type,
      install_parsec              = var.post_install["install_parsec"],
      install_auto_login          = var.post_install["install_auto_login"],
      install_graphic_card_driver = var.post_install["install_graphic_card_driver"],
      install_steam               = var.post_install["install_steam"],
      install_gog_galaxy          = var.post_install["install_gog_galaxy"],
      install_origin              = var.post_install["install_origin"],
      install_epic_games_launcher = var.post_install["install_epic_games_launcher"],
      install_uplay               = var.post_install["install_uplay"],
    }
  })
  iam_instance_profile = aws_iam_instance_profile.windows_instance_profile.id

  # Spot configuration
  spot_type            = "one-time"
  wait_for_fulfillment = true
  hibernation          = true

  provisioner "local-exec" {
    command = join("", formatlist("aws ec2 create-tags --resources ${self.spot_instance_id} --tags Key=\"%s\",Value=\"%s\" --region=${data.aws_region.current.name}; ", keys(self.tags), values(self.tags)))
  }

  provisioner "local-exec" {
    command = "for eachVolume in `aws ec2 describe-volumes --region ${data.aws_region.current.name} --filters Name=attachment.instance-id,Values=${self.spot_instance_id} | jq -r .Volumes[].VolumeId`; do ${join("", formatlist("aws ec2 create-tags --resources $eachVolume --tags          Key=\"%s\",Value=\"%s\" --region=${data.aws_region.current.name}; ", keys(self.tags), values(self.tags)))} done;"
  }

  # Get a random subnet to play with
  subnet_id = random_shuffle.subnet_id.result[0]

  lifecycle {
    ignore_changes = [subnet_id]
  }

  # EBS configuration
  ebs_optimized = true
  root_block_device {
    volume_size           = var.root_block_device_size_gb
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(var.additional_tags, {
    Name = "${var.instance_name}-instance"
  })
}

# Bucket for storing games
# resource "aws_s3_bucket" "games_bucket" {
#   bucket        = "${var.instance_name}-bucket"
#   acl           = "private"
#   force_destroy = false

#   lifecycle_rule {
#     enabled = true
#     transition {
#       storage_class = "INTELLIGENT_TIERING"
#     }
#   }

#   # Don't destroy the bucket even on stack destruction
#   lifecycle {
#     prevent_destroy = true
#   }

#   tags = merge(var.additional_tags, {
#     Name = "${var.instance_name}-bucket"
#   })
# }
