
# ec2 instances variables
variable "ec2_count" {
  description = "The number of EC2 instances to launch"
  default     = 10
}

variable "ami" {
  description = "The AMI to use for the EC2 instances"
  default     = "ami-00016c578cbc69023"
  
}

variable "instance_type" {
  description = "The type of EC2 instance to launch"
  default     = "t2.micro"
  
}


# Lambnda Variables

variable "function_name" {
    description = "The name of the Lambda function"
    default     = "patch_instances"
}