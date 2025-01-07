
# ec2 instances variables
variable "ec2_count" {
  description = "The number of EC2 instances to launch"
  default     = 10
}

variable "ami" {
  description = "The AMI to use for the EC2 instances"
  default     = "ami-00016c578cbc69023" # amzn2-ami-kernel-5.10-hvm-2.0.20241031.0-x86_64-ebs
}

variable "instance_type" {
  description = "The type of EC2 instance to launch"
  default     = "t2.micro"

}

# Lambda Variables
variable "function_name" {
  description = "The name of the Lambda function"
  default     = "patch_instances"
}