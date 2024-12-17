provider "aws" {
  profile = "terraform_3"
  region  = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main"
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "example" {
  name        = "security-group"
  description = "Example security group for SSH and HTTP access"
  vpc_id      = aws_vpc.main.id

 
  ingress {
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the world (adjust for security)
  }

  ingress {
    description = "Allow HTTP access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules
  egress {
    description =  "Allow outbound traffic only on port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
  description = "Allow all outbound traffic"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"  # This allows all protocols
  cidr_blocks = ["0.0.0.0/0"]
}

}
resource "aws_key_pair" "example" {
  key_name   = "my-key-pair"
  public_key = file("D:/Project 1/test.pub")   # Replace with the path to your public key file
}

resource "aws_instance" "example" {
  ami           = "ami-0e2c8caa4b6378d8c"  # Replace with a valid AMI ID for your region
  instance_type = "t2.micro"  # Choose the instance type
  vpc_security_group_ids = [aws_security_group.example.id]  
  subnet_id = aws_subnet.main.id
  key_name = "my-key-pair"
  tags = {
    Name = "MyExampleInstance"
  }
   user_data = <<-EOF
              #!/bin/bash
              # Update the system
              sudo yum update -y

              # Install Java (Jenkins requires Java)
              sudo amazon-linux-extras enable java-openjdk11
              sudo yum install -y java-11-openjdk-devel

              # Add Jenkins repository
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/jenkins.io.key

              # Install Jenkins
              sudo yum install -y jenkins

              # Start Jenkins service
              sudo systemctl start jenkins

              # Enable Jenkins to start on boot
              sudo systemctl enable jenkins

              # Open Jenkins port (8080)
              sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
              sudo service iptables save

              # Display Jenkins status and initial setup instructions
              sudo systemctl status jenkins
              EOF
  # If you want to create a public IP for the instance
  associate_public_ip_address = true
}