variable "region" {
    default = "ap-south-1"
}

variable "amis" {
    type    = map
    default = {
        "us-east-1":"ami-062f7200baf2fa504"
        "ap-south-1":"ami-0123b531fc646552f"
    } 
}
