# 飞牛OS证书更新与服务重启脚本

[English version](README.en.md)

> **请使用root权限执行**  
> **网络问题请自行解决**

这是一个专为飞牛OS（Feiniu OS）系统设计的 Bash 脚本，用于自动更新 SSL/TLS 证书。脚本利用 acme.sh 工具进行证书续期，使用阿里云 DNS 进行域名验证，确保证书在过期前得到更新。更新后，脚本会备份旧证书并替换为新证书，同时自动重启相关服务以确保新证书生效。

## 使用教程
1. 将一下三个参数置空，填写好其他配置，bash执行脚本，即可获取到证书。
```
old_crt: ""
old_key: ""
old_fullchain: ""
```

```
/bin/bash /path/to/update_cert.sh
```
2. 将证书在飞牛-设置-安全性-证书上传后，通过 cat /usr/trim/etc/network_cert_all.conf 获取old_crt、old_key、old_fullchain参数，填写yaml文件中
3. 开启定时，每日执行即可

## 功能特点

- **证书续期**：自动检查 SSL 证书的有效期，并在剩余有效天数少于 7 天时进行自动续期。
- **备份与替换**：在更新证书之前，将旧证书备份到指定目录，更新完毕后替换为新证书。
- **服务重启**：更新证书后，自动重启指定服务（如 `webdav.service`、`smbftpd.service`、`trim_nginx.service`），确保新证书生效。
- **阿里云 API 集成**：使用阿里云 API 密钥进行 DNS 域名验证，确保证书续期过程顺利进行。
- **飞牛OS专用**：专为飞牛OS环境下的证书管理设计，适配飞牛OS的目录结构和服务管理方式。
- **多种证书源支持**：支持acme.sh、lucky以及1panel等多种证书源，满足不同场景需求。

## 环境要求

- 飞牛OS系统环境
- Bash Shell
- 配备阿里云 API 访问权限并具备 DNS 管理权限
- root 权限，以执行服务重启和证书文件操作

## 新增lucky获取证书，并自动替换fnos证书的脚本。教程：
https://club.fnnas.com/forum.php?mod=viewthread&tid=12158&page=1&extra=#pid59164

## 新增1panel证书更新功能
现在支持从1panel推送的证书目录中获取证书并自动更新到飞牛OS中。1panel自带证书申请功能，可以方便地申请和续期证书，并支持设置证书推送和更新后执行自定义脚本。

### 使用方法
1. 在1panel中申请证书并设置证书推送到指定目录（默认为`/vol2/1000/data/acme`）
2. 配置`update_cert_1panel.yaml`文件，设置正确的证书路径和飞牛OS证书位置
3. 执行脚本更新证书：
```
/bin/bash /path/to/update_cert_1panel.sh
```
4. 可选：在1panel的证书管理中设置证书更新后执行脚本，实现自动化更新

## 常见问题

- 网页版https访问正常，飞牛APP访问提示不安全
- 中间证书没有上传和替换，将中间证书添加并替换即可解决这一问题。

## 配置文件说明

脚本需要一个 YAML 配置文件（`update_cert.yaml`），文件内容格式如下：

```yaml
# 证书名称 / 域名 / 同时也是飞牛os上传的证书名 / 需要注意，如果生成的泛域名的话，需要填写fnos正确的证书名称，泛域名一般为 *.abc.cn
fnos_cert_name: "abc.cn"  

# acme生成的证书名称，acme生成的证书一般没有*. 可以先生成看一下
acme_cert_name: "abc.cn"  

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
# 此三项可以为空字符串，为空的话，会生成证书，在飞牛上传证书后再使用  cat /usr/trim/etc/network_cert_all.conf 就可以拿到这三个参数
# 示例： "/path/to/old/certificate.crt"
old_crt: "/usr/trim/var/trim_connect/ssls/abc.cn/1744127279/abc.cn.crt"
old_key: "/usr/trim/var/trim_connect/ssls/abc.cn/1744127279/abc.cn.key"
old_fullchain: "/usr/trim/var/trim_connect/ssls/abc.cn/1744127279/fullchain.crt"

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
```

### 1panel配置文件示例（update_cert_1panel.yaml）
```yaml
# 飞牛OS证书名称 / 域名 / 注意自己上传之后是否是泛域名，泛域名为*.abc.cn,普通域名则为abc.cn
fnos_cert_name: "*.abc.cn"  

# 1panel证书目录
panel_cert_path: "/vol2/1000/data/acme"

# 旧证书备份目录路径
backup_dir: "/vol2/1000/Tools/Cert/Backup"

# 飞牛OS证书位置  上传证书之后使用此命令找：  cat /usr/trim/etc/network_cert_all.conf
old_crt: "/usr/trim/var/trim_connect/ssls/*.abc.cn/1744122157/*.abc.cn.crt"
old_key: "/usr/trim/var/trim_connect/ssls/*.abc.cn/1744122157/*.abc.cn.key"

# 旧的中间证书，1panel生成的证书包含中间证书，如果有请填写
old_fullchain: ""
```

## 许可证

本项目采用 MIT 许可证 - 详情请参见 [LICENSE](LICENSE) 文件。


