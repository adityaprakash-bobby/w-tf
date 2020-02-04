provider "aws" {
    region = "ap-south-1"
}

# Create a launch configuration to be used by the ASG
resource "aws_launch_configuration" "webserver" {
    image_id        = "ami-0620d12a9cf777c87"
    instance_type   = "t2.micro"
    security_groups = [aws_security_group.webserver.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello World from $(hostname)!" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

    # Changes the way the tf handles resource deletion. Ensures a new LC is
    # created before deleting the current one in case of modiftications to LC.
    lifecycle {
        create_before_destroy = true
    }
}

# Create an ASG for the webservers
resource "aws_autoscaling_group" "webserver" {
    name                      = "Simple Webserver ASG"
    max_size                  = 5
    min_size                  = 2
    health_check_grace_period = 300
    health_check_type         = "ELB"
    desired_capacity          = 3
    launch_configuration      = aws_launch_configuration.webserver.name
    vpc_zone_identifier       = data.aws_subnet_ids.default.ids
    target_group_arns         = [aws_lb_target_group.webserver-tg.arn]

    tag {
        key                 = "Name"
        value               = "tf-webserver-asg"
        propagate_at_launch = true  
    }
}

resource "aws_lb" "webserver" {
    name = "webserver-elb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.lb.id]
    subnets = data.aws_subnet_ids.default.ids
}

resource "aws_lb_listener" "httplistener" {
    load_balancer_arn = aws_lb.webserver.arn
    port              = 80
    protocol          = "HTTP"

    # send 404 response if any requests don't match
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: Page not found"
            status_code  = 404
        }
    }
}

resource "aws_lb_target_group" "webserver-tg" {
    name     = "webserver-tg-asg"
    port     = var.server_port
    protocol = "HTTP"
    vpc_id   = data.aws_vpc.default.id

    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener_rule" "webserver-tg-listenerrule" {
    listener_arn = aws_lb_listener.httplistener.arn
    priority     = 100
    
    condition {
        path_pattern {
            values = ["*"]
        }        
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.webserver-tg.arn
    }
}


resource "aws_security_group" "webserver" {
    name = "terraform-example-instance"

    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "lb" {
    name = "terraform-example-lb-sg"
    
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Get VPC and subnet data for use in ASGs
data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}