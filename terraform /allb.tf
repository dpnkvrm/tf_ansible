# Create target group
resource "aws_alb_target_group" "web_tg" {
  name = "${local.project_name}-Web-TG"
  target_type = "instance"
  port = 8080
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc.id
}

# ALB Security Group
resource "aws_security_group" "pub_alb_sg" {
  name        = "${local.project_name}_pub_alb_sg"
  description = "Allow inbound traffic to ALB."
  vpc_id      = aws_vpc.vpc.id
  egress {
    from_port = 0
    protocol  = "tcp"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outgoing traffic"
  }
  ingress {
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound traffic to ALB"
  }
}

resource "aws_security_group_rule" "alb_to_asg_sg" {
  from_port         = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.web_server_sg.id
  source_security_group_id = aws_security_group.pub_alb_sg.id
  to_port           = 8080
  type              = "ingress"
  description = "Allow connection from ALB on Port 8080"
}

resource "aws_lb" "web" {
  name               = "${local.project_name}-Pub-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.pub_alb_sg.id]
  subnets            = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1b.id
  ]
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    forward {
      target_group {
        arn = aws_alb_target_group.web_tg.arn
      }
    }
  }
}
