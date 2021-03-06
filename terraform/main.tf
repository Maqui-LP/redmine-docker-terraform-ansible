terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.64"
    }
    uptimerobot = {
      source  = "louy/uptimerobot"
      version = "~> 0.5.1"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_db_instance" "redmine-db" {
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t2.micro"
  parameter_group_name    = "default.mysql8.0"
  username                = "root"
  password                = var.root_db_pass
  maintenance_window      = var.maintenance_window
  backup_window           = var.backup_window
  backup_retention_period = var.backup_retention_period
  snapshot_identifier     = var.backup_snapshot_identifier
  apply_immediately       = false # Specifies whether any database modifications are applied immediately, or during the next maintenance window
  skip_final_snapshot     = true
  vpc_security_group_ids  = ["${aws_security_group.rds_sg.id}"]

  tags = {
    Name        = "Redmine"
    Environment = "Production"
  }

}

resource "aws_ebs_volume" "ebs" {
  availability_zone = aws_instance.redmine_app.availability_zone
  size              = 8

  tags = {
    Name        = "Redmine"
    Environment = "Production"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs.id
  instance_id = aws_instance.redmine_app.id

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./mpoisson.pem")
    host        = aws_instance.redmine_app.public_ip
  }
}

resource "aws_instance" "redmine_app" {
  ami                    = "ami-0279c3b3186e54acd" #Ubuntu 18.04
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.redmine_sg.id}"]
  key_name               = "mpoisson"

  provisioner "remote-exec" {
    inline = ["echo 'Waiting till SSH is ready' "]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./mpoisson.pem")
      host        = aws_instance.redmine_app.public_ip
    }
  }

  tags = {
    Name        = "Redmine"
    Environment = "Production"
  }
}

resource "null_resource" "Ansible" {

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ./mpoisson.pem -i '${aws_instance.redmine_app.public_ip}', ../provisioning/playbook.yml"

  }
  depends_on = [
    aws_instance.redmine_app, local_file.tf_ansible_vars
  ]

}

output "redmine_app_ip" {
  value = aws_instance.redmine_app.public_ip
}
output "redmine_db_ip" {
  value = aws_db_instance.redmine-db.address
}
