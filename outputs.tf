output "vpc_id" {
  value = aws_vpc.main.id
}

output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

output "bastion_public_ip" {
  value = aws_eip.bastion.public_ip
}