variable "aws_region" {
    description = "The AWS region where the resources are created"
    type        = "string"
    default     = "eu-west-2"
}

variable "cloudflare_zone" {
    description = "The CloudFlare domain name"
    type        = "string"
    default     = "loganair.co.uk"
}

variable "cloudflare_email" {
    description = "The CloudFlare account name"
    type        = "string"
    default     = ""
}

variable "cloudflare_token" {
    description = "The CloudFlare API key"
    type        = "string"
    default     = ""
}

variable "bucket_name" {
    description = "The name of the bucket to be created to hold files accessible by SFTP"
    type        = "string"
    default     = "loganair-sftp"
}

variable admin_pubkey {
    description = "The RSA public key for the admin account"
    type        = "string"
    default     = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAjeqjHvaeDTuDp2ByM7hcWrgHEubs8B4W0BYXXOP4HOHCG5O+RsbMXhm9KunOOFjBpl+YtQqN8AFLtRvvtyvoyPYnt6XVI6NLjVBLjLdl7ReECkw5j9libYaqqMn9CiGe/cQIiblHtjUmeGDpNf54BWXzt66FguxdFsfqlji/Hux995Opq17Vbr1MO2019XYVvDmMVpN2MmjvvYRA1vDID6JyQXpxuqgrdULAhPOupxUI90YvgOT+N/vS8CQcdhOulN0sC0eUYfJ0BnT5ssH0u1XzfvzGsDjDiyfhdt11WCkIuDMiEldDwVokL2TXCbGqF4cbbwhZQfLYQdMPo+JBCw== logadmin"
}

# Additional users can be added below if required - the username and RSA public key are required
variable "sftp_accounts" {
    default = [
        {
            name = "accelya"
            key  = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAkx7U71NIW9MM6iz/em0k9E6rPnhxJrkUmuDaDugBQ147uCUbYR+Nv0LAZ3bLLo/upq6OmWUtKaiX/IjjN8rClBMOwBW14xugLahQ5mQm8N54mWaIjLknlt1uDZMiTBjZIXAMwRAHerxWp102VYswHrWMyshNThLH8ITU82hKcE7MsAUxNIhg4fZ21EicROqyhluL7kddsAp0fpaAOahX2rrK3k3dojWmo9jd4f6CPjeXRZha8k3MO79M2B45nFVcXRWWNCNCdmDYd23zj2ord4+Y2AD9E0tN+IQ/5EXgEeBvXysrHOAwBBo/t7bmRT5sfyWcbOyXZapadCN3rGfNBw== accelya"
        }
    ]
}
