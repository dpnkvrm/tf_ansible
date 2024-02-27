provider "tls" {
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "generated_key" {
  public_key = tls_private_key.ssh_key.public_key_openssh
  key_name = "${local.project_name}_web_server_key"
}

# ASG Security Group
resource "aws_security_group" "web_server_sg" {
  name        = "${local.project_name}_web_server_sg"
  description = "Allow inbound traffic to Web Server."
  vpc_id      = aws_vpc.vpc.id
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outgoing traffic"
  }

}

resource "aws_security_group_rule" "pub_to_asg_sg_22" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.web_server_sg.id
  cidr_blocks = ["0.0.0.0/0"]
  to_port           = 22
  type              = "ingress"
  description = "Allow connection from public to ssh"
}

data "aws_ami" "ubuntu" {

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Create Launch Configuration
resource "aws_launch_template" "web_server" {
  name                 = "${local.project_name}-Web_Server"
  image_id             = data.aws_ami.ubuntu.image_id
  instance_type        = "t2.micro"
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.web_server_sg.id]
  }
  key_name = aws_key_pair.generated_key.key_name
}

# Create Autoscaling Group
resource "aws_autoscaling_group" "web_server_asg" {

  name                 = "${local.project_name}-Web_Server-ASG"
  launch_template {
    name = aws_launch_template.web_server.name
  }
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  force_delete = true
  target_group_arns = [aws_alb_target_group.web_tg.arn]
  vpc_zone_identifier  = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1b.id
  ]
  tag {
    key                 = "Name"
    value               = "${local.project_name}-Web_Server"
    propagate_at_launch = true
  }
}

# Create IAM User
resource "aws_iam_user" "web_server_user" {
  name = "${local.project_name}-web_server_user"
}

# Create IAM Policy for Restarting Web Server
resource "aws_iam_policy" "web_server_restart_policy" {
  name        = "${local.project_name}-web_server_restart_policy"
  description = "Allows restarting the web server instance"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:RebootInstances",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/Name": "${local.project_name}-Web_Server"
        }
      }
    }
  ]
}
EOF
}

# Attach IAM Policy to IAM User
resource "aws_iam_user_policy_attachment" "web_server_policy_attachment" {
  user       = aws_iam_user.web_server_user.name
  policy_arn = aws_iam_policy.web_server_restart_policy.arn
}
