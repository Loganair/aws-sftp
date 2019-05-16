variable "aws_region" {
    description = "The AWS region where the resources are created"
    type        = "string"
    default     = "eu-west-2"
}

variable "buckets" {
    description = "The name of the buckets to be created for SFTP"
    type        = "list"
    default     = ["accelya-sftp","loganair-sftp"]
}

variable "rw_accounts" {
    default = ["accelya-rw", "loganair-rw"]
}

variable "put_accounts" {
    default = ["accelya-put", "loganair-put"]
}
