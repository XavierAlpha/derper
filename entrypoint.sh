#!/bin/sh
check_cert() {
    if [ "$CERT_MODE" = "letsencrypt" ]; then
        echo "使用 Let's Encrypt 获取证书, 请合理配置域名（跳过自建证书）"
        return
    elif [ "$CERT_MODE" = "manual" ]; then
        echo "手动证书模式"
        if [ -f "$CERT_DIR/$HOSTNAME.crt" ] && [ -f "$CERT_DIR/$HOSTNAME.key" ]; then
            echo "$CERT_DIR 文件夹中证书已存在且格式正确"
            return
        elif [ -f "*.crt" ] && [ -f "*.key" ]; then
            echo "$CERT_DIR 文件夹中证书已存在但格式错误, 退出"
            exit 1
        else
            echo "$CERT_DIR 文件夹中不存在证书文件。生成自签名证书"
            cat > "$CONF_FILE" <<EOF
[req]
default_md = sha256
prompt = no
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
C = US
ST = California
L = Los Angeles
O = Camellia Corp
OU = Camellia Corp
CN = ${HOSTNAME}

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
IP.1 = $HOSTNAME
EOF
            mkdir -p "$CERT_DIR"
            openssl ecparam -name prime256v1 -genkey -noout -out "$CERT_DIR/$HOSTNAME.key"
            openssl req -x509 -nodes -new -key "$CERT_DIR/$HOSTNAME.key" -days 365 -out "$CERT_DIR/$HOSTNAME.crt" -config "$CONF_FILE"
        fi
    else
        echo "未知的 CERTMODE 环境变量: $CERT_MODE"
        exit 1
    fi
}

check_cert
exec "$@"