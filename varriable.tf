variable "vpc_cidr" {

default = "172.17.0.0/16"

}
variable "project" {

  default = "zomato"
}

variable "image" {

  default = "ami-04893cdb768d0f9ee"

}

variable "key" {

default = "devops-new"

}

variable "instance_type" {

default = "t2.micro"
}


variable "count_asgone" {

default = "2"

}
