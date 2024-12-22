#!/bin/sh
if [ "$CERT_MODE" = "letsencrypt" ]; then
    echo "使用 Let's Encrypt 获取证书, 请合理配置域名（跳过自建证书）"
elif [ "$CERT_MODE" = "manual" ]; then
    echo "手动证书模式"
    if [ -f "$CERT_DIR/$HOSTNAME.crt" ] && [ -f "$CERT_DIR/$HOSTNAME.key" ]; then
        echo "找到外部证书，使用映射的证书"
    else
        echo "错误：$CERT_DIR 文件夹中未找到 $HOSTNAME.crt 和 $HOSTNAME.key 文件。"
        exit 1
    fi
    else
        echo "没有找到外部证书，生成自签名证书"
        CONF_FILE="ASN.conf"
        echo "[req]
        default_bits  = 2048
        distinguished_name = req_distinguished_name
        req_extensions = req_ext
        x509_extensions = v3_req
        prompt = no
        
        [req_distinguished_name]
        countryName = US
        stateOrProvinceName = California
        localityName = Los Angeles
        organizationName = Self-signed
        organizationalUnitName = Self-signed
        commonName = $HOSTNAME
        emailAddress = admin@$HOSTNAME

        [req_ext]
        subjectAltName = @alt_names
        
        [v3_req]
        subjectAltName = @alt_names
        
        [alt_names]
        IP.1 = $HOSTNAME
        " > "$CONF_FILE"
        
        mkdir -p "$CERT_DIR"
        openssl req -x509 -nodes -quiet -days 730 -newkey rsa:2048 -keyout "$CERT_DIR/$HOSTNAME.key" -out "$CERT_DIR/$HOSTNAME.crt" -config "$CONF_FILE"
    fi

else
    echo "未知的 CERTMODE 环境变量: $CERT_MODE"
    exit 1
fi

exec "$@"