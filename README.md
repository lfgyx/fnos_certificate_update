# 飞牛OS证书更新与服务重启脚本

[English version](README.en.md)

> **请使用root权限执行**  
> **网络问题请自行解决**

这是一个专为飞牛OS（Feiniu OS）系统设计的 Bash 脚本，用于自动更新 SSL/TLS 证书。脚本利用 acme.sh 工具进行证书续期，使用阿里云 DNS 进行域名验证，确保证书在过期前得到更新。更新后，脚本会备份旧证书并替换为新证书，同时自动重启相关服务以确保新证书生效。

## 功能特点

- **证书续期**：自动检查 SSL 证书的有效期，并在剩余有效天数少于 7 天时进行自动续期。
- **备份与替换**：在更新证书之前，将旧证书备份到指定目录，更新完毕后替换为新证书。
- **服务重启**：更新证书后，自动重启指定服务（如 `webdav.service`、`smbftpd.service`、`trim_nginx.service`），确保新证书生效。
- **阿里云 API 集成**：使用阿里云 API 密钥进行 DNS 域名验证，确保证书续期过程顺利进行。
- **飞牛OS专用**：专为飞牛OS环境下的证书管理设计，适配飞牛OS的目录结构和服务管理方式。

## 环境要求

- 飞牛OS系统环境
- Bash Shell
- 配备阿里云 API 访问权限并具备 DNS 管理权限
- root 权限，以执行服务重启和证书文件操作

## 新增lucky获取证书，并自动替换fnos证书的脚本。教程：
https://club.fnnas.com/forum.php?mod=viewthread&tid=12158&page=1&extra=#pid59164

## 常见问题

- 网页版https访问正常，飞牛APP访问提示不安全
- 中间证书没有上传和替换，将中间证书添加并替换即可解决这一问题。

## 配置文件说明

脚本需要一个 YAML 配置文件（`update_cert.yaml`），文件内容格式如下：

```yaml
# 证书的名称，通常是你为证书选择的域名或服务名称。
# 示例： "baidu.com"
cert_name: "example.com"

# 证书的保存路径，即存放证书和密钥文件的目录。
# 示例： "./cert"  或  "/path/to/cert"
cert_path: "/path/to/cert"

# 证书更新之前，旧证书的备份存放目录。
# 备份时，旧证书将移动到该目录下，以便后续恢复或查看。
# 示例： "./backup"  或  "/path/to/backup"
backup_dir: "/path/to/backup"

# 用于申请和更新证书时的联系邮箱地址。
# 该邮箱将用于接收关于证书到期等重要信息。
# 示例： "user@example.com"
email: "user@example.com"

# 阿里云 API 密钥，用于 DNS 验证域名所有权。
# 需要在阿里云控制台获取 API 密钥。
# 示例： "your_aliyun_api_key"
Ali_Key: "your_aliyun_api_key"

# 阿里云 API 密钥的 Secret，和 API 密钥配合使用。
# 示例： "your_aliyun_api_secret"
Ali_Secret: "your_aliyun_api_secret"

# 飞牛OS证书位置  上传证书之后使用此命令找：  cat /usr/trim/etc/network_cert_all.conf
# 该路径指向你当前正在使用的证书文件，脚本会根据该证书判断是否需要更新。
# 示例： "/path/to/old/certificate.crt"
old_crt: "/path/to/old/certificate.crt"
old_key: "/path/to/old/private.key"

# 域名列表，包含需要申请证书的所有域名。
# 这些域名将在证书申请过程中使用，用于验证域名的所有权并生成证书。
# 注意：必须至少包含一个域名。
# 示例：
# domains:
#   - "example.com"
#   - "*.example.com"   *代表通配符域名，可以验证所有此域名下的二级域名
domains:
  - "example.com"
  - "*.example.com"



## 许可证

本项目采用 MIT 许可证 - 详情请参见 [LICENSE](LICENSE) 文件。


