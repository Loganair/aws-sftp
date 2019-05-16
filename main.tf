provider "aws" {
    version = "~> 2.0"
    region  = "${var.aws_region}"
}

#provider "cloudflare" {
#    email = ""
#    token = ""
#}

provider "template" {
    version = "~> 1.0"
}

terraform {
    required_version = "~> 0.11"

    backend "s3" {
        bucket         = "loganair-terraform-state"
        key            = "aws-sftp-server/terraform.tfstat"
        region         = "eu-west-2"
        encrypt        = true
        dynamodb_table = "loganair-terraform-state-lock"
    }
}

locals {
    s3_arn        = "arn:aws:s3:::"
    s3_arn_ending = "/*"
}

# Format home directory string correctly - it must begin with a "/"
data "template_file" "home_dirs" {
    count    = "${length(var.buckets)}"
    template = "${format("/%s", var.buckets[count.index])}"
}

# String manipulation to dynamically create the resource portion of the admin policy
data "template_file" "admin_arn_1" {
    count    = "${length(var.buckets)}"
    template = "${format("\"%s%s\"", local.s3_arn, var.buckets[count.index])}"
}

data "template_file" "admin_arn_2" {
    count    = "${length(var.buckets)}"
    template = "${format("\"%s%s%s\"", local.s3_arn, var.buckets[count.index], local.s3_arn_ending)}"
}

# Import the JSON policy files
data "template_file" "assume_role_policy" {
    template = "${file("policies/assume-role-policy.json.tpl")}"
}

data "template_file" "cloudwatch_logging_policy" {
    template = "${file("policies/cloudwatch-logging-policy.json.tpl")}"
}

data "template_file" "admin_policy" {
    template = "${file("policies/admin-policy.json.tpl")}"

    vars {
        arn1 = "${join(", ", data.template_file.admin_arn_1.*.rendered)}"
        arn2 = "${join(", ", data.template_file.admin_arn_2.*.rendered)}"
    }
}

##########################################
# Role and policy for CloudWatch logging #
##########################################
resource "aws_iam_role" "cloudwatch_logging" {
    name               = "AWSSFTPLogging"
    description        = "Provides the ability to create logs in Amazon Cloudwatch"
    assume_role_policy = "${data.template_file.assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "cloudwatch_logging_policy" {
    name   = "AWSSFTPLoggingPolicy"
    role   = "${aws_iam_role.cloudwatch_logging.id}"
    policy = "${data.template_file.cloudwatch_logging_policy.rendered}"
}

####################################
# Role and policy for admin access #
####################################
resource "aws_iam_role" "sftp_admin" {
    name               = "AWSSFTPAdmin"
    description        = "Provides read/write access to all S3 buckets accessible via SFTP"
    assume_role_policy = "${data.template_file.assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "sftp_admin_policy" {
    name   = "AWSSFTPAdminPolicy"
    role   = "${aws_iam_role.sftp_admin.id}"
    policy = "${data.template_file.admin_policy.rendered}"
}

############################################
# Role and policy for standard user access #
############################################
resource "aws_iam_role" "sftp_read_write" {
    name               = "AWSSFTPReadWrite"
    description        = "Provides read/write access to the Accelya S3 bucket via SFTP"
    assume_role_policy = "${data.template_file.assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "accelya_read_write_policy" {
    name   = "AWSSFTPAccelyaReadWritePolicy"
    role   = "${aws_iam_role.accelya_read_write.id}"
    policy = "${data.template_file.admin_read_write_policy.rendered}"
}





resource "aws_transfer_user" "logadmin" {
    server_id      = "${aws_transfer_server.loganair-sftp.id}"
    user_name      = "logadmin"
    home_directory = "/accelya-sftp"
    role           = "${aws_iam_role.sftp_admin.arn}"
}

resource "aws_transfer_ssh_key" "logadmin_key" {
    server_id = "${aws_transfer_server.loganair-sftp.id}"
    user_name = "${aws_transfer_user.logadmin.user_name}"
    body      = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAmbkJTsNeaCTULT+/3jYpNKmBjqmxTmMDhjxiNpCfOvPwfAWGfoTbYYAcB9hM6EXUEhLcOCUkiXGpMsiTOKlG1Jeyx0BGWmudxOn24zW7M8fERQSNYbGbCwBezpUhEfJii82CvV34rxGLvz2KpfTZzwqfUR0J2gAoCQPtgzueBkimD6Ol86Y42wL7wYfZfMf4Sgdx1RaqWBAJ6f5IgPOv6s8Vp4jIGr3Wn5De4m2SQv7UMP00p3fBsYB3G5POhrbTZU6L/AYQn6U657AlmWekcJNmx+nyORy7K87hFTtw8CBytDtfitbU3xfQAtKYfHNXqU0k6fUqYhfhPKOJlluf2w== rsa-key-20190514"
}

# Create the required S3 buckets
resource "aws_s3_bucket" "this" {
    count  = "${length(var.buckets)}"
    bucket = "${var.buckets[count.index]}"
    acl    = "private"

    versioning = {
        enabled = true
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }

    tags = {
        Name        = "AWS SFTP Server"
        Environment = "Production"
    }
}

# Create the AWS SFTP server
resource "aws_transfer_server" "loganair-sftp" {
    endpoint_type          = "PUBLIC"
    identity_provider_type = "SERVICE_MANAGED"
    logging_role           = "${aws_iam_role.cloudwatch_logging.arn}"
    force_destroy          = true

    tags = {
        Name        = "AWS SFTP Server"
        Environment = "Production"
    }
}

## Add a record to the domain
#resource "cloudflare_record" "sftp" {
#  domain  = "${var.cloudflare_zone}"
#  name    = "sftp"
#  value   = "${aws_transfer_server.name.endpoint}"
#  type    = "CNAME"
#  proxied = false
#  ttl     = 3600
#}
