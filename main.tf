resource "aws_security_group" "main" {
  name        = "${local.name_prefix}-sg"
  description = "${local.name_prefix}-sg"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${local.name_prefix}-sg" })

  ingress {
    description = "APP"
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = var.sg_ingress_cidr
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ingress_cidr
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_launch_template" "main" {
  name   = local.name_prefix
  image_id      = data.aws_ami.ami.id
  instance_type = var.instance_type
  vpc_security_group_ids =[aws_security_group.main.id]

  user_data = filebase64(templatefile("${path.module}/userdata.sh",
    {
      component=var.component
    }))
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags, { Name = "${local.name_prefix}-ec2" })

  }
  /*iam_instance_profile {.

    name = "test"
  }*/
}

resource "aws_autoscaling_group" "main" {
  name = "${local.name_prefix}-asg"
  vpc_zone_identifier =var.subnet_ids
  availability_zones = ["us-east-1a"]
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = local.name_prefix
    propagate_at_launch = true
  }
}
resource "aws_route53_record" "main" {
  zone_id = var.zone_id
  name    = var.component == "frontend" ? var.env : "${var.component}-${var.env}"
  type    = "CNAME"
  ttl     = 30
  records = [var.alb_name]
}

resource "aws_lb_target_group" "main" {
  name     = local.name_prefix
  port     = var.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}
resource "aws_lb_listener_rule" "main" {
  listener_arn = var.listener
  priority     = var.lb_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["${var.component}-${var.env}.dljrobo.online"]
    }
  }

}
