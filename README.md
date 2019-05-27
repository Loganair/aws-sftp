![Logo](https://raw.github.com/Loganair/aws-sftp/master/images/loganair.png)

# AWS Secure File Transfer Protocol (SFTP)

## WinSCP Setup

```Shell
File protocol: SFTP
Host name: sftp.loganair.co.uk
Port number: 22
User name: <your user name>
Password: leave blank
```

Public key cryptogtaphy is used to authenticate users to the SFTP server rather than passwords. To set the private key for the account, do the following:

1. Click "Advanced" under the Password box.
2. Choose SSH > Authentication.
3. Click the "..." icon next to the "Private key file" box.

## Server Building

When building or altering the SFTP server configuration the following variables should be set in your PowerShell session. For obvious reasons the required values are detailed elsewhere.

```shell
$Env:AWS_ACCESS_KEY_ID="<aws id>"
$Env:AWS_SECRET_ACCESS_KEY="<aws key>"
$Env:TF_VAR_cloudflare_email="<cloudflare account>"
$Env:TF_VAR_cloudflare_token="<cloudflare api key>"
```

A simple `terraform apply` in the same directory as the code will build or alter the configuraion as required.
