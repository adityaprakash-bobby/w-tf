provider "aws" {
    region = "ap-south-1"
}

resource "aws_instance" "example" {
    ami                    = "ami-0620d12a9cf777c87"
    instance_type          = "t2.micro"
    vpc_security_group_ids = [aws_security_group.terraform-instance.id]

    user_data = file("start-server.sh")

    tags = {
        Name = "terraform-example"
    }
}

resource "aws_security_group" "terraform-instance" {
    name = "terraform-example-instance"

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}