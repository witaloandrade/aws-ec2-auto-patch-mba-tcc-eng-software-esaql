## EC2 instances
resource "aws_instance" "example" {
  count                = var.ec2_count
  ami                  = var.ami
  instance_type        = var.instance_type
  iam_instance_profile = "AmazonSSMRoleForInstancesQuickSetup"

  tags = {
    Name       = "instance-${count.index}"
    auto-patch = "second-tuesday-00"
  }
}