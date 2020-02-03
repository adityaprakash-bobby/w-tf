output "server_ip" {
    description = "Pulic IP of the webserver"
    value = aws_instance.example.public_ip
}