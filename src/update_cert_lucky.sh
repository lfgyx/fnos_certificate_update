#!/bin/bash

# 获取当前脚本的目录
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# 设置配置文件的完整路径
CONFIG_FILE="$SCRIPT_DIR/update_cert_lucky.yaml"

# 检查文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件 $CONFIG_FILE 不存在！"
    exit 1
fi

# 读取配置文件中的配置项
FNOS_CERT_NAME=$(grep -oP '(?<=fnos_cert_name: ")[^"]+' "$CONFIG_FILE")
LUCKY_CERT_NAME=$(grep -oP '(?<=lucky_cert_name: ")[^"]+' "$CONFIG_FILE")
CERT_PATH=$(grep -oP '(?<=cert_path: ")[^"]+' "$CONFIG_FILE")
BACKUP_DIR=$(grep -oP '(?<=backup_dir: ")[^"]+' "$CONFIG_FILE")
OLD_CRT=$(grep -oP '(?<=old_crt: ")[^"]+' "$CONFIG_FILE")
OLD_KEY=$(grep -oP '(?<=old_key: ")[^"]+' "$CONFIG_FILE")
OLD_FULLCHAIN=$(grep -oP '(?<=old_fullchain: ")[^"]+' "$CONFIG_FILE")

# 检查是否读取到所有必要的信息
if [ -z "$FNOS_CERT_NAME" ] || [ -z "$LUCKY_CERT_NAME" ] || [ -z "$CERT_PATH" ] || [ -z "$BACKUP_DIR" ] || [ -z "$OLD_CRT" ] || [ -z "$OLD_KEY" ]; then
    echo "配置文件中缺少必需的信息！"
    exit 1
fi

echo "$OLD_CRT"

# 检查旧证书文件是否存在
if [ ! -f "$OLD_CRT" ] || [ ! -f "$OLD_KEY" ]; then
    echo "旧证书文件不存在！"
    exit 1
fi

echo "配置文件读取成功！"
echo "飞牛证书名称: $FNOS_CERT_NAME"
echo "lucky证书名称: $LUCKY_CERT_NAME"
echo "证书路径: $CERT_PATH"
echo "备份目录: $BACKUP_DIR"
echo "旧证书路径: $OLD_CRT"
echo "旧密钥路径: $OLD_KEY"

# 创建必要的目录（如果不存在）
echo "检查并创建证书文件备份目录 $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"


# 备份旧证书文件到备份目录
echo "备份旧证书文件到 $BACKUP_DIR..."
BACKUP_DATE=$(date +%F)  # 获取年月日格式
mv "$OLD_CRT" "$BACKUP_DIR/$(basename $OLD_CRT)_$BACKUP_DATE"
mv "$OLD_KEY" "$BACKUP_DIR/$(basename $OLD_KEY)_$BACKUP_DATE"

# 将新证书文件复制到旧证书文件的路径
echo "将新证书文件复制到 $OLD_CRT 和 $OLD_KEY..."
cp "$CERT_PATH/$LUCKY_CERT_NAME.pem" "$OLD_CRT"
cp "$CERT_PATH/$LUCKY_CERT_NAME.key" "$OLD_KEY"

    
# 设置新证书文件权限为 755
chmod 755 "$OLD_CRT"
chmod 755 "$OLD_KEY"
echo "已为新证书文件设置 755 权限"
   
# 如果有中间证书，则处理中间证书
if [ -n "$OLD_FULLCHAIN" ]; then
    mv "$OLD_FULLCHAIN" "$BACKUP_DIR/$(basename "$OLD_FULLCHAIN")_$BACKUP_DATE"
    cp "$CERT_PATH/$LUCKY_CERT_NAME.fullchain.crt" "$OLD_FULLCHAIN"
	chmod 755 "$OLD_FULLCHAIN"
fi

# 获取新证书的到期日期并更新数据库中的证书有效期
NEW_EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$OLD_CRT" | sed "s/^.*=\(.*\)$/\1/")
NEW_EXPIRY_TIMESTAMP=$(date -d "$NEW_EXPIRY_DATE" +%s%3N)  # 获取毫秒级时间戳
echo "新证书的有效期到: $NEW_EXPIRY_DATE"

# 更新数据库中的证书有效期
echo "更新数据库中的证书有效期..."
psql -U postgres -d trim_connect -c "UPDATE cert SET valid_to=$NEW_EXPIRY_TIMESTAMP WHERE domain='$FNOS_CERT_NAME'"


echo "证书更新完成！"

# 重启服务
echo "正在重启相关服务..."
systemctl restart webdav.service
systemctl restart smbftpd.service
systemctl restart trim_nginx.service
echo "服务重启完成！"
