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

# Import the required IAM policies
data "template_file" "iam_role_policy" {
    template = "${file("policies/role-policy.json")}"
}

data "template_file" "read_write_policy" {
    template = "${file("policies/read-write-policy.json")}"

    vars {
        bucket = "${aws_s3_bucket.accelya.id}"
    }
}

# Create the required roles and policies
resource "aws_iam_role" "accelya_read_write" {
    name               = "AWSSFTPAccelyaReadWrite"
    description        = "Provides read/write access to the Accelya S3 bucket via SFTP"
    assume_role_policy = "${data.template_file.iam_role_policy.rendered}"
}

resource "aws_iam_role_policy" "accelya_read_write_policy" {
    name   = "AWSSFTPAccelyaReadWrite-Policy"
    role   = "${aws_iam_role.accelya_read_write.id}"
    policy = "${data.template_file.read_write_policy.rendered}"
}

resource "aws_transfer_user" "logadmin" {
    server_id = "${aws_transfer_server.loganair-sftp.id}"
    user_name = "logadmin"
    role      = "${aws_iam_role.accelya_read_write.arn}"
}

resource "aws_transfer_ssh_key" "logadmin_key" {
    server_id = "${aws_transfer_server.loganair-sftp.id}"
    user_name = "${aws_transfer_user.logadmin.user_name}"
    body      = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAmbkJTsNeaCTULT+/3jYpNKmBjqmxTmMDhjxiNpCfOvPwfAWGfoTbYYAcB9hM6EXUEhLcOCUkiXGpMsiTOKlG1Jeyx0BGWmudxOn24zW7M8fERQSNYbGbCwBezpUhEfJii82CvV34rxGLvz2KpfTZzwqfUR0J2gAoCQPtgzueBkimD6Ol86Y42wL7wYfZfMf4Sgdx1RaqWBAJ6f5IgPOv6s8Vp4jIGr3Wn5De4m2SQv7UMP00p3fBsYB3G5POhrbTZU6L/AYQn6U657AlmWekcJNmx+nyORy7K87hFTtw8CBytDtfitbU3xfQAtKYfHNXqU0k6fUqYhfhPKOJlluf2w== rsa-key-20190514"
}

# Create the S3 bucket for the Accelya files
resource "aws_s3_bucket" "accelya" {
    bucket = "accelya-sftp"
    acl    = "private"
    
    versioning = {
        enabled = true
    }
}

resource "aws_transfer_server" "loganair-sftp" {
    endpoint_type          = "PUBLIC"
    identity_provider_type = "SERVICE_MANAGED"
    #logging_role           = ""

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
