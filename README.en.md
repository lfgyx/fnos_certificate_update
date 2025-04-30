# Feiniu OS Certificate Update and Service Restart Script

[中文版本](README.md)

> **Please execute with root privileges**  
> **Please resolve network issues on your own**

This is a Bash script designed specifically for the Feiniu OS system, used to automatically update SSL/TLS certificates. The script utilizes the acme.sh tool for certificate renewal and uses Alibaba Cloud DNS for domain verification to ensure the certificate is updated before it expires. After updating, the script will back up the old certificate, replace it with the new one, and automatically restart related services to ensure the new certificate takes effect.

## Features

- **Certificate Renewal**: Automatically checks the SSL certificate's validity period and renews it when less than 7 days remain.
- **Backup and Replacement**: Backs up the old certificate before updating and replaces it with the new one after renewal.
- **Service Restart**: Automatically restarts specified services (such as `webdav.service`, `smbftpd.service`, `trim_nginx.service`) after the certificate is updated to ensure the new certificate is applied.
- **Alibaba Cloud API Integration**: Uses Alibaba Cloud API keys for DNS domain validation, ensuring a smooth certificate renewal process.
- **Feiniu OS Specific**: Designed for certificate management in Feiniu OS, adapted to its directory structure and service management.
- **Multiple Certificate Sources**: Supports acme.sh, lucky, and 1panel certificate sources to meet different requirements.

## System Requirements

- Feiniu OS system environment
- Bash Shell
- Alibaba Cloud API access with DNS management permissions
- Root privileges to perform service restarts and certificate file operations


## Add a script to get a lucky certificate and automatically replace the FNOS certificate. Tutorial:
https://club.fnnas.com/forum.php?mod=viewthread&tid=12158&page=1&extra=#pid59164

## New 1panel Certificate Update Feature
Now supports retrieving certificates from 1panel's certificate push directory and automatically updating them to Feiniu OS. 1panel has built-in certificate application functionality, making it easy to apply for and renew certificates, and supports setting up certificate push and executing custom scripts after updates.

### Usage
1. Apply for a certificate in 1panel and set up certificate push to a specified directory (default is `/vol2/1000/data/acme`)
2. Configure the `update_cert_1panel.yaml` file, setting the correct certificate path and Feiniu OS certificate location
3. Run the script to update the certificate:
```
/bin/bash /path/to/update_cert_1panel.sh
```
4. Optional: Set up execution of the script after certificate updates in 1panel's certificate management for automated updates

## Common Problem

- The web version of HTTPS access is normal, but the Feiniu APP prompts unsafe access
- The intermediate certificate has not been uploaded or replaced. Adding and replacing the intermediate certificate can solve this problem.

## Configuration File Description

The script requires a YAML configuration file (`update_cert.yaml`) with the following format:

```yaml
# Certificate name, typically the domain or service name you choose for the certificate.
# Example: "baidu.com"
cert_name: "example.com"

# The directory where the certificate and key files will be saved.
# Example: "./cert" or "/path/to/cert"
cert_path: "/path/to/cert"

# The directory to store backups of the old certificate before updating.
# The old certificate will be moved to this directory for future restoration or inspection.
# Example: "./backup" or "/path/to/backup"
backup_dir: "/path/to/backup"

# Email address used for certificate issuance and renewal notifications.
# This email will receive important messages about certificate expiration and updates.
# Example: "user@example.com"
email: "user@example.com"

# Alibaba Cloud API key for DNS domain verification.
# You need to obtain this API key from the Alibaba Cloud console.
# Example: "your_aliyun_api_key"
Ali_Key: "your_aliyun_api_key"

# The Secret for the Alibaba Cloud API key, used together with the API key.
# Example: "your_aliyun_api_secret"
Ali_Secret: "your_aliyun_api_secret"

# Feiniu OS certificate location: After uploading the certificate, use this command to find it:  
# cat /usr/trim/etc/network_cert_all.conf
# This path points to your currently used certificate file, which the script will check to determine if an update is needed.
# Example: "/path/to/old/certificate.crt"
old_crt: "/path/to/old/certificate.crt"
old_key: "/path/to/old/private.key"

# List of domains for which the certificate should be issued.
# These domains will be used for domain ownership verification and certificate generation.
# Note: At least one domain must be included.
# Example:
# domains:
#   - "example.com"
#   - "*.example.com"   # * represents a wildcard domain, verifying all second-level domains under this domain
domains:
  - "example.com"
  - "*.example.com"
```

### 1panel Configuration File Example (update_cert_1panel.yaml)
```yaml
# Feiniu OS certificate name / domain / Note whether it's a wildcard domain (*.abc.cn) or a regular domain (abc.cn)
fnos_cert_name: "*.abc.cn"  

# 1panel certificate directory
panel_cert_path: "/vol2/1000/data/acme"

# Old certificate backup directory
backup_dir: "/vol2/1000/Tools/Cert/Backup"

# Feiniu OS certificate location. After uploading the certificate, use this command to find it: cat /usr/trim/etc/network_cert_all.conf
old_crt: "/usr/trim/var/trim_connect/ssls/*.abc.cn/1744122157/*.abc.cn.crt"
old_key: "/usr/trim/var/trim_connect/ssls/*.abc.cn/1744122157/*.abc.cn.key"

# Old intermediate certificate path. 1panel generated certificates include intermediate certificates. Can be left empty if not needed.
old_fullchain: ""
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
