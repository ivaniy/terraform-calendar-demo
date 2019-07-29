resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "terraform_db_subnet"
  subnet_ids = "${var.subnet_ids}"
  description = "Managed by Terraform Private DB Subnet Group"
  tags = {
    Name = "Private DB Subnet Gr"
    Type = "Private"
  }
}

resource "random_string" "db_pass" {
  length = 20
  special = true
  override_special = "#%&*()-_=+[]<>:?"
}

resource "aws_db_instance" "db_instance" {
  allocated_storage         = 20
  storage_type              = "gp2"
  engine                    = "mysql"
  engine_version            = "5.7"
  instance_class            = "db.t2.micro"
  identifier                = "${var.identifier}"  # Instance identifier (name)
#  name                      = "calendar_db"  # Database name (optional)
  username                  = "calendar_db_user" #Master Username
  password                  = "${random_string.db_pass.result}" # Every run wil be change password
  parameter_group_name      = "default.mysql5.7"
  backup_retention_period   = 0 # no backups 
  copy_tags_to_snapshot     = true
  db_subnet_group_name      = "${aws_db_subnet_group.db_subnet_group.name}"
  multi_az                  = false
  max_allocated_storage     = 0
  vpc_security_group_ids    = ["${aws_security_group.dbsg.id}"]
  publicly_accessible       = false #This is def value
  skip_final_snapshot       = true
  deletion_protection       = false  # Default is false

  tags = {
    Name = "Calendar DB Instance"
  }
}

output "db_address" {
   value = "${aws_db_instance.db_instance.address}" 
}

output "db_pass" {
   value = "${random_string.db_pass.result}" 
}
