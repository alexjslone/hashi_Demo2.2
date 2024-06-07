variable "region" {
  description = "The AWS region in which the resources will be created."
  type        = string
  default     = "us-west-1"
}

variable "availability_zone" {
  description = "The availability zone where the resources will reside."
  type        = string
  default     = "us-west-1a"
#should I put in something like data.aws_availability_zones.available.names[0] # First available AZ
#which would give me the first available zone? 

}
variable "ami" {
  description = "The ID of the Amazon Machine Image (AMI) used to create the EC2 instance."
  type        = string
  default     = "ami-08012c0a9ee8e21c4"
}
variable "instance_type" {
  description = "The type of EC2 instance used to create the instance."
  type        = string
  default     = "t2.micro"
}