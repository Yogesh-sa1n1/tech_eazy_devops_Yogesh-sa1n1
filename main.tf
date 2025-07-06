provider "aws" {	
  region  = var.region
}

variable "bucket_name" {
description = "Name of the S3 bucket to store logs"
type = string
}

# Ensure bucket_name is provided
locals {
validated_bucket_name = length(trimspace(var.bucket_name)) > 0 ? var.bucket_name : (throw("Error: bucket_name variable must be provided"))
}


resource "tls_private_key" "keyPair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "javaServer"
  public_key = tls_private_key.keyPair.public_key_openssh
}

resource "local_file" "pemFile" {
  content         = tls_private_key.keyPair.private_key_pem
  filename        = "${path.module}/javaServer.pem"
  file_permission = "0600"
}

resource "aws_security_group" "securityGroup" {
	name = "javaServerSG"
	description = "allow ssh access and tcp 8080"
	
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]		
	}
	
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_iam_role" "readOnlyS3" {
	name="ReadOnlyS3"
	assume_role_policy = jsonencode({
	Version = "2012-10-17"
	Statement = [{
		Effect = "Allow",
		Principal = {
			Service = "ec2.amazonaws.com"
		},
		Action = "sts:AssumeRole"
	}]
	})
}

resource "aws_iam_role_policy_attachment" "readOnlyS3_attach" {
	role = aws_iam_role.readOnlyS3.name
	policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role" "writeOnlyS3"{
	name = "WriteOnlyS3"
	assume_role_policy = jsonencode({
		Version = "2012-10-17"
		Statement=[{
			Effect = "Allow"
			Principal = {
				Service = "ec2.amazonaws.com"
			},
			Action = "sts:AssumeRole"
		}]	
	})
}

data "aws_iam_policy_document" "writeOnlyS3Policy" {
	statement{
		effect = "Allow"
		actions = [
			"s3:CreateBucket",
			"s3:PutObject"
		]
		resources=[
			"arn:aws:s3:::*",
			"arn:aws:s3:::*/*"
		]
	}
}

resource "aws_iam_policy" "writeOnlyS3Policy" {
	name = "WriteOnlyS3Policy"
	policy = data.aws_iam_policy_document.writeOnlyS3Policy.json
}

resource "aws_iam_role_policy_attachment" "attachWriteOnly"{
	role = aws_iam_role.writeOnlyS3.name
	policy_arn = aws_iam_policy.writeOnlyS3Policy.arn
}
 
resource "aws_iam_instance_profile" "ec2_profile" {
name = "EC2WriteOnlyProfile"
role = aws_iam_role.writeOnlyS3.name
} 

resource "aws_instance" "ec2_instance" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.securityGroup.id]
  user_data = templatefile("${path.module}/user_data.sh.tmpl", {
  stage = var.stage
  shutdown_delay_minutes = var.shutdown_delay_minutes
  validated_bucket_name = local.validated_bucket_name
  })
  
  tags = {
    Name = "JavaServer"
    Team = var.stage
  }
}

resource "aws_s3_bucket" "log_bucket" {
bucket = local.validated_bucket_name

tags = {
Name = "Log Archive Bucket"
}

}

resource "aws_s3_bucket_ownership_controls" "log_bucket_ownership" {
bucket = aws_s3_bucket.log_bucket.id

rule {
object_ownership = "BucketOwnerEnforced"
}
}


resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
bucket = aws_s3_bucket.log_bucket.id

rule {
id = "log-cleanup"
status = "Enabled"

expiration {
days = 7
}

filter {
prefix = ""
}
}
}



output "ec2_public_ip" {
  value = aws_instance.ec2_instance.public_ip
}

output "key_pair_name" {
  value = aws_key_pair.generated_key.key_name
}

