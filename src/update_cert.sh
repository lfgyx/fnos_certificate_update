#!/bin/bash

# 获取当前脚本的目录
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# 设置配置文件的完整路径
CONFIG_FILE="$SCRIPT_DIR/update_cert.yaml"

# 检查文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件 $CONFIG_FILE 不存在！"
    exit 1
fi

# 读取配置文件中的配置项
CERT_NAME=$(grep -oP '(?<=cert_name: ")[^"]+' "$CONFIG_FILE")
CERT_PATH=$(grep -oP '(?<=cert_path: ")[^"]+' "$CONFIG_FILE")
BACKUP_DIR=$(grep -oP '(?<=backup_dir: ")[^"]+' "$CONFIG_FILE")
EMAIL=$(grep -oP '(?<=email: ")[^"]+' "$CONFIG_FILE")
ALI_KEY=$(grep -oP '(?<=Ali_Key: ")[^"]+' "$CONFIG_FILE")
ALI_SECRET=$(grep -oP '(?<=Ali_Secret: ")[^"]+' "$CONFIG_FILE")
OLD_CRT=$(grep -oP '(?<=old_crt: ")[^"]+' "$CONFIG_FILE")
OLD_KEY=$(grep -oP '(?<=old_key: ")[^"]+' "$CONFIG_FILE")
OLD_FULLCHAIN=$(grep -oP '(?<=old_fullchain: ")[^"]+' "$CONFIG_FILE")

# 使用 sed 提取 domains 部分的域名，忽略空行并删除前导空格，同时去除 `-` 和引号
DOMAINS=$(sed -n '/domains:/,/^[[:space:]]*$/p' "$CONFIG_FILE" | grep -v 'domains:' | sed 's/^[[:space:]]*//g' | sed 's/- //g' | sed 's/"//g' | tr '\n' ' ')

# 检查是否读取到所有必要的信息
if [ -z "$CERT_NAME" ] || [ -z "$CERT_PATH" ] || [ -z "$BACKUP_DIR" ] || [ -z "$EMAIL" ] || [ -z "$DOMAINS" ] || [ -z "$ALI_KEY" ] || [ -z "$ALI_SECRET" ] || [ -z "$OLD_CRT" ] || [ -z "$OLD_KEY" ]; then
    echo "配置文件中缺少必需的信息！"
    exit 1
fi

# 检查旧证书文件是否存在
if [ ! -f "$OLD_CRT" ] || [ ! -f "$OLD_KEY" ]; then
    echo "旧证书文件不存在！"
    exit 1
fi

# 计算证书文件的有效期
echo "检查证书有效期..."
EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$OLD_CRT" | sed "s/^.*=\(.*\)$/\1/")
EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
CURRENT_TIMESTAMP=$(date +%s)

# 计算证书过期剩余天数
REMAIN_DAYS=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))

echo "证书有效期到: $EXPIRY_DATE"
echo "剩余有效天数: $REMAIN_DAYS"

# 如果证书有效期剩余天数大于 7 天，则不执行后续操作，直接退出
if [ $REMAIN_DAYS -gt 7 ]; then
    echo "证书有效期剩余超过7天，不需要更新，退出脚本"
    exit 0
fi

echo "配置文件读取成功！"
echo "证书名称: $CERT_NAME"
echo "证书路径: $CERT_PATH"
echo "备份目录: $BACKUP_DIR"
echo "邮箱: $EMAIL"
echo "域名: $DOMAINS"
echo "阿里云 API 密钥: $ALI_KEY"
echo "阿里云 API 密钥 Secret: $ALI_SECRET"
echo "旧证书路径: $OLD_CRT"
echo "旧密钥路径: $OLD_KEY"

# 创建必要的目录（如果不存在）
echo "检查并创建证书文件保存目录 $CERT_PATH 和备份目录 $BACKUP_DIR..."
mkdir -p "$CERT_PATH"
mkdir -p "$BACKUP_DIR"

# 使用 curl 安装 acme.sh 并传递邮箱配置
echo "正在安装 acme.sh，使用邮箱 $EMAIL..."
curl https://get.acme.sh | sh -s email="$EMAIL"

# 配置阿里云 API 密钥
echo "正在配置阿里云密钥..."
export Ali_Key="$ALI_KEY"
export Ali_Secret="$ALI_SECRET"

# 拼接多个域名作为 -d 参数
DOMAIN_ARGS=""
for DOMAIN in $DOMAINS; do
    DOMAIN_ARGS="$DOMAIN_ARGS -d $DOMAIN"
done

# 申请证书并为多个域名生成证书
echo "申请证书：$DOMAINS"
~/.acme.sh/acme.sh --issue --dns dns_ali $DOMAIN_ARGS --force

# 保存证书到指定目录
echo "将证书保存到 $CERT_PATH"
~/.acme.sh/acme.sh --install-cert -d "$CERT_NAME" \
    --cert-file "$CERT_PATH/$CERT_NAME.crt" \
    --key-file "$CERT_PATH/$CERT_NAME.key" \
    --fullchain-file "$CERT_PATH/$CERT_NAME.fullchain.crt"

# 备份旧证书文件到备份目录
echo "备份旧证书文件到 $BACKUP_DIR..."
BACKUP_DATE=$(date +%F)  # 获取年月日格式
mv "$OLD_CRT" "$BACKUP_DIR/$(basename $OLD_CRT)_$BACKUP_DATE"
mv "$OLD_KEY" "$BACKUP_DIR/$(basename $OLD_KEY)_$BACKUP_DATE"
mv "$OLD_FULLCHAIN" "$BACKUP_DIR/$(basename $OLD_FULLCHAIN)_$BACKUP_DATE"
echo "已备份文件 $OLD_CRT 到 $BACKUP_DIR/$(basename $OLD_CRT)_$BACKUP_DATE"
echo "已备份文件 $OLD_KEY 到 $BACKUP_DIR/$(basename $OLD_KEY)_$BACKUP_DATE"

# 将新证书文件复制到旧证书文件的路径
echo "将新证书文件复制到 $OLD_CRT 和 $OLD_KEY..."
cp "$CERT_PATH/$CERT_NAME.crt" "$OLD_CRT"
cp "$CERT_PATH/$CERT_NAME.key" "$OLD_KEY"
cp "$CERT_PATH/$CERT_NAME.fullchain.crt" "$OLD_FULLCHAIN"
echo "新证书文件已复制到 $OLD_CRT 和 $OLD_KEY 路径"


# 设置新证书文件权限为 755
chmod 755 "$OLD_CRT"
chmod 755 "$OLD_KEY"
chmod 755 "$OLD_FULLCHAIN"
echo "已为新证书文件设置 755 权限"

# 获取新证书的到期日期并更新数据库中的证书有效期
NEW_EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERT_PATH/$CERT_NAME.crt" | sed "s/^.*=\(.*\)$/\1/")
NEW_EXPIRY_TIMESTAMP=$(date -d "$NEW_EXPIRY_DATE" +%s%3N)  # 获取毫秒级时间戳
echo "新证书的有效期到: $NEW_EXPIRY_DATE"

# 更新数据库中的证书有效期
echo "更新数据库中的证书有效期..."
psql -U postgres -d trim_connect -c "UPDATE cert SET valid_to=$NEW_EXPIRY_TIMESTAMP WHERE domain='$CERT_NAME'"

# 清理临时文件
echo "清理临时文件..."
~/.acme.sh/acme.sh --remove -d "$CERT_NAME"

echo "证书更新完成！"

# 重启服务
echo "正在重启相关服务..."
systemctl restart webdav.service
systemctl restart smbftpd.service
systemctl restart trim_nginx.service
echo "服务重启完成！"