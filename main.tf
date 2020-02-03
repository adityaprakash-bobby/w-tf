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

    tag {
        key                 = "Name"
        value               = "tf-webserver-asg"
        propagate_at_launch = true  
    }
}

# Get VPC and subnet data for use in ASGs
data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
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