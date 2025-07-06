# AWS EC2 Java App Infrastructure with Auto Log Upload to S3

This Terraform project provisions an AWS EC2 instance to run a Java Spring Boot application and automatically uploads system and app logs to an S3 bucket during shutdown.

## 📦 Features

- EC2 instance provisioning with SSH key pair
- Java 21 installation using user data
- Spring Boot app deployment using `mvnw`
- S3 bucket with lifecycle rules for logs
- IAM roles for EC2 with write access to S3
- Logs include:
  - `/var/log/cloud-init.log`
  - `app.log` from the deployed app

---

## 🚀 Technologies Used

- Terraform
- AWS EC2, S3, IAM
- Java 21
- Spring Boot
- AWS CLI
- Ubuntu / Amazon Linux compatible

---

## 📁 Project Structure
.
├── main.tf # Main Terraform configuration
├── variables.tf # Input variables
├── outputs.tf # Output values like EC2 IP and key name
├── user_data.sh.tmpl # User data script for EC2 instance initialization



### 1. Initialize Terraform
            terraform init
### 2. Apply the Configuration
            sudo terraform apply -var-file="dev.tfvars"
            sudo terraform apply -var-file="prod.tfvars"
