<img src="https://raw.github.com/Loganair/aws-sftp/master/images/loganair.png" alt="Logo" width="300">

# AWS Secure File Transfer Protocol (SFTP)

## WinSCP Setup

WinSCP is a free Windows-based SFTP client that should be used to upload and download files from the SFTP server. It can be obtained from the [WinSCP site](https://winscp.net/eng/download.php).

After WinSCP is installed it should be configured with the settings detailed in the sections below. All configuration steps will be described from the "Login (New Site)" dialog box.

![WinSCP Login](https://raw.github.com/Loganair/aws-sftp/master/images/winscp-login.png)

### Timestamp settings

Storage for AWS SFTP is provided by Amazon Simple Storage Service (S3) which does not support manually setting file timestamps. To prevent an `The server does not support the operation. SETSTAT unsupported` error when uploading files, the WinSCP "Preserve timestamp" setting should be disabled:

1. Click "Tools" then "Preferences..."
2. In the preferences dialog box, click "Transfer".
3. Ensure "**Default**" is selected in "Transfer settings presets" and click "Edit..."
4. Uncheck "Preserve timestamp" under "Common options".
5. Click "Ok" twice.

![Timestamp Settings](https://raw.github.com/Loganair/aws-sftp/master/images/timestamp-settings.png)

### Private key settings

Public key cryptography is used to authenticate users to the SFTP server instead of passwords. To set the private key for the account, do the following:

1. Click "Advanced" under the Password box.
2. Choose SSH > Authentication.
3. Click the "..." icon next to the "Private key file" box.
4. Browse to the location of the private key file (\*.ppk) and choose "Open".
5. Click "Ok" to return to the Login dialog box.

![Advanced Settings](https://raw.github.com/Loganair/aws-sftp/master/images/advanced-settings.png)

### Server settings

Once the timestamp and private key settings have been configured, the server details should be entered and saved so subsequent logins will not require any typing.

Enter the following details in the "Login (New Site)" dialog box then click "Save":

```Shell
File protocol: SFTP
Host name: sftp.loganair.co.uk
Port number: 22
User name: <the user name given to you>
Password:
```

In the "Save session as site" dialog box, Enter "Loganair SFTP" as the "Site name" and click "Ok".

For subsequent logins, the user can simply choose the saved "Loganair SFTP" site on the left-hand side and then click "Login".

## Server Building

The SFTP server is build entirely via [Terraform](https://terraform.io).

When building or altering the SFTP server configuration the following variables should be set in your PowerShell session. For obvious reasons the required values are detailed elsewhere.

```shell
$Env:AWS_ACCESS_KEY_ID="<aws id>"
$Env:AWS_SECRET_ACCESS_KEY="<aws key>"
$Env:TF_VAR_cloudflare_email="<cloudflare account>"
$Env:TF_VAR_cloudflare_token="<cloudflare api key>"
```

A simple `terraform apply` in the same directory as the code will build or alter the configuration as required.
