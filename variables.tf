variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "instance_count" {
  default = 2
}

variable "amis" {
  default = ["ami-0ea3c35c5c3284d82", "ami-0ea3c35c5c3284d82"]
}
