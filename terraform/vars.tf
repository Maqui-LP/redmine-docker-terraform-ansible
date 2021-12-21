
variable "root_db_pass" {
  type    = string
  default = "rootpass"
}

variable "redmine_db_pass" {
  type    = string
  default = "password"
}

variable "use_externalDB" {
  type    = string
  default = "true"
}

variable "secret_key_base" {
  type = string
  default = "5a37811464e7d378488b0f073e2193b093682e4e21f5d6f3ae0a4e1781e61a351fdc878a843424e81c73fb484a40d23f92c8dafac4870e74ede6e5e174423010"
}

variable "var_environment" {
  type = string
  default = "production"
}
# The window to perform maintenance in. Syntax: "ddd:hh24:mi-ddd:hh24:mi". 
# Eg: "Mon:00:00-Mon:03:00".
variable "maintenance_window" {
  type    = string
  default = "Sun:23:45-Mon:01:45"
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

# The daily time range (in UTC) during which automated backups are created if they are enabled. 
# Example: "09:46-10:16". Must not overlap with maintenance_window
variable "backup_window" {
  type    = string
  default = "02:30-03:30"
}

variable "backup_snapshot_identifier" {
  type    = string
  default = ""
}

resource "local_file" "tf_ansible_vars" {
  content = yamlencode(
    {
      db_host = aws_db_instance.redmine-db.address
      redmine_db_pass = var.redmine_db_pass
      root_db_pass = var.root_db_pass
      use_externalDB = var.use_externalDB
      secret_key_base = var.secret_key_base
    }
  ) 
  filename = "../provisioning/vars/tf_ansible_vars.yml"
}