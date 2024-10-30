terraform {
  backend "s3" {
    bucket         = "champions-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  tags = {
    Name = var.name
  }


  provisioner "file" 
  {
    source      = "index.html"
    destination = "/var/www/html/index.html"
  }

  provisioner "remote-exec" 
  {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y apache2",
      "sudo mv /var/www/html/index.html /var/www/html/",
      "sudo systemctl start apache2",
      "sudo systemctl enable apache2"
    ]
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              EOF

  lifecycle {
    create_before_destroy = true
  }
}