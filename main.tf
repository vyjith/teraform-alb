module "vpc" {

  source   = "git::git@github.com:vyjith/vpc-module-terraform.git"
  vpc_cidr = "172.17.0.0/16"
  project  = "zomato"


}

resource "aws_security_group" "freedom" {

  name        = "freedom"
  description = "allows 22,80,443 conntection"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = ""
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    description      = ""
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    description      = ""
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

   tags = {
    Name = "${var.project}-freedom"
    project = var.project
  }

}

# --------------------------------------------------

# Target group for first instance

# --------------------------------------------------

resource "aws_lb_target_group" "tgone" {
  name        = "targetgroup"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id


  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = 200

  }

  lifecycle {
    create_before_destroy = true
  }
}

# --------------------------------------------------

# Application load balancer

# --------------------------------------------------


resource "aws_lb" "albtg" {
  name               = "albfrontend"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.freedom.id ]
  subnets            = [ module.vpc.subnet_public1_id , module.vpc.subnet_public2_id , module.vpc.subnet_public3_id ]

  enable_deletion_protection = false

   depends_on = [ aws_lb_target_group.tgone ]


  tags = {
    Name = var.project
  }
}


# --------------------------------------------------

# Application load balancer listner

# --------------------------------------------------


resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.albtg.arn
  port              = "80"
  protocol          = "HTTP"



# --------------------------------------------------

# Default action

# --------------------------------------------------


default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = " No such Site Found"
      status_code  = "200"
   }
}

}

#-------------------------------------
#First forwording rule
#-------------------------------------

resource "aws_lb_listener_rule" "rule-one" {

  listener_arn = aws_lb_listener.front_end.arn
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tgone.arn
  }

  condition {
    host_header {
      values = [ "${var.project}.vyjithks.tk" ]

}
}
}

#-------------------------------------
# Launch configration
#-------------------------------------


resource "aws_launch_configuration" "webserverlc" {
  name          =  "${var.project}-1"
  image_id      =  var.image
  instance_type =  var.instance_type
  key_name      = var.key
  security_groups = [ aws_security_group.freedom.id ]
  user_data  = file("user.sh")

  lifecycle {
    create_before_destroy = true
}
}

#-------------------------------------
# aws_autoscaling_group
#-------------------------------------


resource "aws_autoscaling_group" "asg-one" {

  launch_configuration    = aws_launch_configuration.webserverlc.id
  health_check_type       = "EC2"
  min_size                = var.count_asgone
  max_size                = var.count_asgone
  desired_capacity        = var.count_asgone
  vpc_zone_identifier     = [ module.vpc.subnet_public1_id , module.vpc.subnet_public2_id , module.vpc.subnet_public3_id ]
  target_group_arns       = [ aws_lb_target_group.tgone.arn ]
  tag {
    key = "Name"
    propagate_at_launch = true
    value = "Asg-one"
  }

  lifecycle {
    create_before_destroy = true
  }
}



#-------------------------------------
# Route 53
#-------------------------------------


resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.id
  name    = "${var.project}.${data.aws_route53_zone.selected.name}"
  type    = "A"

  alias {
    name                   = aws_lb.albtg.dns_name
    zone_id                = aws_lb.albtg.zone_id
    evaluate_target_health = true
  }
}
