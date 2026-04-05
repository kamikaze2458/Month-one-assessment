variable "region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "instance_type_web" {
  description = "Instance type for web and bastion servers"
  default     = "t3.micro"
}

variable "instance_type_db" {
  description = "Instance type for database server"
  default     = "t3.small"
}

variable "key_pair_name" {
  description = "techcorp-key"
}

variable "my_ip" {
  description = "83.137.6.61/32"
}