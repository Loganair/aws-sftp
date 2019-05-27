<img src="https://raw.github.com/Loganair/aws-sftp/master/images/loganair.png" alt="Logo" width="300">

# AWS Secure File Transfer Protocol (SFTP)

## WinSCP Setup

WinSCP is a free Windows-based SFTP client that should be used to upload and download files from the SFTP server.  It can be obtained from the [WinSCP site](https://winscp.net/eng/download.php).

After WinSCP is installed it should be configured with the settings below.  All configuraton steps will be described from the "Login (new site)" dialog box.

<img src="https://raw.github.com/Loganair/aws-sftp/master/images/winscp-login.png" alt="WinSCP Login">

### Timestamp settings

Storage for AWS SFTP is provided by Amazon Simple Storage Service (S3) which does not support manually setting file timestamps.  To prevent an `SETSTAT unsupported` error when uploading files, the WinSCP "Preserve timestamp" setting should be disabled:

1. Click "Tools" then "Preferences..."
2. In the preferences dialog box, click "Transfer".
3. Ensure "**Default**" is selected in "Transfer settings presets" and click "Edit..."
4. Uncheck "Preserve timestamp" under "common options".
5. Click "Ok" twice.

### Private key settings

Public key cryptogtaphy is used to authenticate users to the SFTP server rather than passwords. To set the private key for the account, do the following:

1. Click "Advanced" under the Password box.
2. Choose SSH > Authentication.
3. Click the "..." icon next to the "Private key file" box.
4. Browse to the location of the private key file (*.ppk) and choose "Open".
5. Click "Ok" to return to the Login dialog box.

<img src="https://raw.github.com/Loganair/aws-sftp/master/images/advanced-settings.png" alt="Advanced Settings">

### Server settings

```Shell
File protocol: SFTP
Host name: sftp.loganair.co.uk
Port number: 22
User name: <your user name>
Password: leave blank
```

## Server Building

When building or altering the SFTP server configuration the following variables should be set in your PowerShell session. For obvious reasons the required values are detailed elsewhere.

```shell
$Env:AWS_ACCESS_KEY_ID="<aws id>"
$Env:AWS_SECRET_ACCESS_KEY="<aws key>"
$Env:TF_VAR_cloudflare_email="<cloudflare account>"
$Env:TF_VAR_cloudflare_token="<cloudflare api key>"
```

A simple `terraform apply` in the same directory as the code will build or alter the configuraion as required.
