terraform {
    required_version = "0.12.20"
}

provider "aws" {
    region = "ap-south-1"
}

module "consul" {
    source      = "hashicorp/consul/aws"
    num_servers = 3
}
