provider "aws" {
  region = "us-west-2"
}

//---------------------------------
//---------------------------------
// SECURITY GROUP
//---------------------------------
//---------------------------------

resource "aws_security_group" "demo-sg" {
  name        = "Security group for demo"
  description = "SSH and server port access"
  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Server port access from anywhere
  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Outbound access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//---------------------------------
//---------------------------------
// APPLICATION SERVERS
//---------------------------------
//---------------------------------

resource "aws_instance" "demo-app-server" {
  count                  = 5 
  ami                    = "ami-0fcd5791ba781e98f"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.demo-sg.id}"]
  key_name               = "chris"
  provisioner "file" {
    source      = "demo-app/"
    destination = "/home/ec2-user/"
  }
  provisioner "remote-exec" {
    inline = [
      "curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -",
      "sudo yum -y install nodejs",
      "cd app",
      "sudo npm install",
      "npm run start"
    ]
  }
  connection {
    user        = "ec2-user"
    private_key = "${file("/Users/chris/.ssh/chris.pem")}"
  }
  tags {
    Name = "demo-app-server-${count.index}"
  }
}

//---------------------------------
//---------------------------------
// LOAD BALANCER
//---------------------------------
//---------------------------------

resource "aws_instance" "demo-load-balancer" {
  # depends_on = ["aws_instance.demo-app-server"]
  ami                    = "ami-0fcd5791ba781e98f" 
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.demo-sg.id}"]
  key_name               = "chris"
  provisioner "file" {
    source      = "lb-config/"
    destination = "/home/ec2-user/"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install -y nginx1.12",
      "sudo touch ips.txt",
      "sudo chmod 777 ips.txt",
      "sudo echo ${join(",", aws_instance.demo-app-server.*.public_ip)} >> ips.txt",
      "sudo sh genconf.sh",
      "sudo mkdir cache",
      "sudo nginx -c /home/ec2-user/nginx.conf"
    ]
  }
  connection {
    user        = "ec2-user"
    private_key = "${file("/Users/chris/.ssh/chris.pem")}"
  }
  tags {
    Name = "demo-load-balancer"
  }
}

//---------------------------------
// IP ADDRESSES
//---------------------------------

output "app-public-addresses" {
  value = ["${aws_instance.demo-app-server.*.public_ip}"]
}
output "app-private-addresses" {
  value = ["${aws_instance.demo-app-server.*.private_ip}"]
}
output "lb-public-address" {
  value = "${aws_instance.demo-load-balancer.public_ip}"
}
