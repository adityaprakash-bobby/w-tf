# output "server_ip" {
#     description = "Pulic IP of the webserver"
#     value = aws_instance.example.public_ip
# }

output "webserver_lb_dns_name" {
  value = aws_lb.webserver.dns_name
}
