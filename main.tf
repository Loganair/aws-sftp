provider "aws" {
    version = "~> 2.0"
    region  = "${var.aws_region}"
}

provider "cloudflare" {
    email   = "${var.cloudflare_email}"
    token   = "${var.cloudflare_token}"
    version = "~> 1.14"
}

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

# Import the JSON policy files
data "template_file" "assume_role_policy" {
    template = "${file("policies/assume-role-policy.json.tpl")}"
}

data "template_file" "cloudwatch_logging_policy" {
    template = "${file("policies/cloudwatch-logging-policy.json.tpl")}"
}

data "template_file" "standard_access_policy" {
    template = "${file("policies/standard-access-policy.json.tpl")}"

    vars {
        bucket = "${var.bucket_name}"
    }
}

data "template_file" "restricted_access_policy" {
    template = "${file("policies/restricted-access-policy.json.tpl")}"
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

##########################################
# Role, policy and user for admin access #
##########################################
resource "aws_iam_role" "sftp_admin" {
    name               = "AWSSFTPAdmin"
    description        = "Provides read/write access to the entire S3 SFTP bucket"
    assume_role_policy = "${data.template_file.assume_role_policy.rendered}"
}

resource "aws_iam_policy" "sftp_standard_access_policy" {
    name        = "AWSSFTPStandardAccessPolicy"
    description = "Policy for standard read/write access to the entire S3 SFTP bucket"
    policy      = "${data.template_file.standard_access_policy.rendered}"
}

resource "aws_iam_role_policy_attachment" "sftp_admin_policy" {
    role       = "${aws_iam_role.sftp_admin.id}"
    policy_arn = "${aws_iam_policy.sftp_standard_access_policy.arn}"
}

resource "aws_transfer_user" "logadmin" {
    server_id      = "${aws_transfer_server.loganair-sftp.id}"
    user_name      = "logadmin"
    home_directory = "/${var.bucket_name}"
    role           = "${aws_iam_role.sftp_admin.arn}"
}

resource "aws_transfer_ssh_key" "logadmin_key" {
    server_id = "${aws_transfer_server.loganair-sftp.id}"
    user_name = "${aws_transfer_user.logadmin.user_name}"
    body      = "${var.admin_pubkey}"
}

############################################
# Role and policy for standard user access #
############################################
resource "aws_iam_role" "this" {
    count              = "${length(var.sftp_accounts)}"
    name               = "AWSSFTP${title(lookup(var.sftp_accounts[count.index], "name"))}"
    description        = "Provides read/write access to the ${lookup(var.sftp_accounts[count.index], "name")} folder in the S3 bucket"
    assume_role_policy = "${data.template_file.assume_role_policy.rendered}"
}

resource "aws_iam_role_policy_attachment" "sftp_standard_access_policy" {
    count      = "${length(var.sftp_accounts)}"
    role       = "${element(aws_iam_role.this.*.id, count.index)}"
    policy_arn = "${aws_iam_policy.sftp_standard_access_policy.arn}"
}

resource "aws_transfer_user" "this" {
    count          = "${length(var.sftp_accounts)}"
    server_id      = "${aws_transfer_server.loganair-sftp.id}"
    user_name      = "${lookup(var.sftp_accounts[count.index], "name")}"
    home_directory = "/${var.bucket_name}/${lookup(var.sftp_accounts[count.index], "name")}"
    role           = "${element(aws_iam_role.this.*.arn, count.index)}"
    policy         = "${data.template_file.restricted_access_policy.rendered}"
}

resource "aws_transfer_ssh_key" "this" {
    count      = "${length(var.sftp_accounts)}"
    server_id  = "${aws_transfer_server.loganair-sftp.id}"
    user_name  = "${lookup(var.sftp_accounts[count.index], "name")}"
    body       = "${lookup(var.sftp_accounts[count.index], "key")}"
    depends_on = ["aws_transfer_user.this"]
}

################################################
# Create the required S3 bucket for SFTP files #
################################################
resource "aws_s3_bucket" "loganair-sftp" {
    bucket = "${var.bucket_name}"
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

##############################
# Create the AWS SFTP server #
##############################
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

################################
# Add DNS record to the domain #
################################
resource "cloudflare_record" "sftp" {
  domain  = "${var.cloudflare_zone}"
  name    = "sftp"
  value   = "${aws_transfer_server.loganair-sftp.endpoint}"
  type    = "CNAME"
  proxied = false
  ttl     = 3600
}
