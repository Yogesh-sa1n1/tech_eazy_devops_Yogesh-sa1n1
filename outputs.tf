output "ec2_public_ip" {
  value = aws_instance.ec2_instance.public_ip
}

output "key_pair_name" {
  value = aws_key_pair.generated_key.key_name
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.log_bucket.bucket
  description = "Name of log S3 bucket"
}