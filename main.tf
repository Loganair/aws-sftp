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

#data "template_file" "role_policy" {
#    template = "${file("policies/role-policy.json")}"
#
#    vars {
#        uploader   = "${aws_iam_user.fdm_uploader.arn}"
#        downloader = "${aws_iam_user.fdm_downloader.arn}"
#        admin      = "${aws_iam_user.fdm_admin.arn}"
#    }
#}

#data "template_file" "read_write_policy" {
#    template = "${file("policies/read-write-policy.json")}"
#
#    vars {
#        bucket = "${aws_s3_bucket.accelya.name}"
#    }
#}

resource "aws_s3_bucket" "accelya" {
    bucket = "accelya-sftp"
    acl    = "private"
    
    versioning = {
        enabled = true
    }
}

resource "aws_transfer_server" "name" {
    endpoint_type          = "PUBLIC"
    identity_provider_type = "SERVICE_MANAGED"
    #logging_role           = ""

    tags = {
        Name        = "AWS SFTP Server"
        Environment = "Production"
    }
}

#resource "aws_transfer_user" "logadmin" {
#    server_id = "${aws_transfer_server.name.id}"
#    user_name = "logadmin"
#    role      = ""
#}
#
#resource "aws_transfer_ssh_key" "logadmin" {
#    server_id = "${aws_transfer_server.name.id}"
#    user_name = "${aws_transfer_user.logadmin.user_name}"
#    body      = ""
#}
#
#resource "aws_transfer_user" "accelya" {
#    server_id = "${aws_transfer_server.name.id}"
#    user_name = "accelya"
#    role      = ""
#}
#
#resource "aws_transfer_ssh_key" "accelya" {
#    server_id = "${aws_transfer_server.name.id}"
#    user_name = "${aws_transfer_user.accelya.user_name}"
#    body      = ""
#}
#
## Add a record to the domain
#resource "cloudflare_record" "sftp" {
#  domain  = "${var.cloudflare_zone}"
#  name    = "sftp"
#  value   = "${aws_transfer_server.name.endpoint}"
#  type    = "CNAME"
#  proxied = false
#  ttl     = 3600
#}
