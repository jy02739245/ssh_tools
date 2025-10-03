#!/bin/bash

# 介绍信息
echo -e "\e[32m
  ____   ___   ____ _  ______ ____  
 / ___| / _ \ / ___| |/ / ___| ___|  
 \___ \| | | | |   | ' /\___ \___ \ 
  ___) | |_| | |___| . \ ___) |__) |           不要直连
 |____/ \___/ \____|_|\_\____/____/            没有售后   
 缝合怪：cmliu 原作者们：RealNeoMan、k0baya、eooce
\e[0m"

# 获取当前用户名
USER=$(whoami)
LOWER_USER=$(echo "${USER}" | tr 'A-Z' 'a-z')
WORKDIR="/home/${USER}/.nezha-agent"
FILE_PATH="/home/${USER}/.s5"

###################################################

socks5_config(){
# 提示用户输入socks5端口号
read -p "请输入socks5端口号: " SOCKS5_PORT

# 提示用户输入用户名和密码
read -p "请输入socks5用户名: " SOCKS5_USER

while true; do
  read -p "请输入socks5密码（不能包含@和:）：" SOCKS5_PASS
  echo
  if [[ "$SOCKS5_PASS" == *"@"* || "$SOCKS5_PASS" == *":"* ]]; then
    echo "密码中不能包含@和:符号，请重新输入。"
  else
    break
  fi
done

# config.json文件（修正版）
cat > ${FILE_PATH}/config.json << EOF
{
  "log": {
    "access": "/dev/null",
    "error": "/dev/null",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $SOCKS5_PORT,
      "protocol": "socks",
      "tag": "socks",
      "settings": {
        "auth": "password",
        "udp": false,
        "userLevel": 0,
        "accounts": [
          {
            "user": "$SOCKS5_USER",
            "pass": "$SOCKS5_PASS"
          }
        ]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
}

install_socks5(){
  socks5_config
  if [ ! -e "${FILE_PATH}/s5" ]; then
    curl -L -sS -o "${FILE_PATH}/s5" "https://github.com/eooce/test/releases/download/amd64/web"
  else
    read -p "socks5 程序已存在，是否重新下载覆盖？(Y/N 回车N)" downsocks5
    downsocks5=$(echo "${downsocks5}" | tr 'a-z' 'A-Z') # 转换为大写
    if [ "$downsocks5" == "Y" ]; then
      if pgrep s5 > /dev/null; then
        pkill s5
        echo "socks5 进程已被终止"
      fi
      curl -L -sS -o "${FILE_PATH}/s5" "https://github.com/eooce/test/releases/download/amd64/web"
    else
      echo "使用已存在的 socks5 程序"
    fi
  fi

  if [ -e "${FILE_PATH}/s5" ]; then
    chmod +x "${FILE_PATH}/s5"
    nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &
	  sleep 2
    pgrep -x "s5" > /dev/null && echo -e "\e[1;32ms5 is running\e[0m" || { echo -e "\e[1;35ms5 is not running, restarting...\e[0m"; pkill -x "s5" && nohup "${FILE_PATH}/s5" -c ${FILE_PATH}/config.json >/dev/null 2>&1 & sleep 2; echo -e "\e[1;32ms5 restarted\e[0m"; }
    CURL_OUTPUT=$(curl -s 4.ipw.cn --socks5 $SOCKS5_USER:$SOCKS5_PASS@localhost:$SOCKS5_PORT)
    if [[ $CURL_OUTPUT =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "代理创建成功，返回的IP是: $CURL_OUTPUT"
      SERV_DOMAIN=$CURL_OUTPUT
      # 查找并列出包含用户名的文件夹
      found_folders=$(find "/home/${USER}/domains" -type d -name "*${LOWER_USER}*")
      if [ -n "$found_folders" ]; then
          if echo "$found_folders" | grep -q "serv00.net"; then
              SERV_DOMAIN="${LOWER_USER}.serv00.net"
          elif echo "$found_folders" | grep -q "ct8.pl"; then
              SERV_DOMAIN="${LOWER_USER}.ct8.pl"
          fi
      fi

      echo "socks://${SOCKS5_USER}:${SOCKS5_PASS}@${SERV_DOMAIN}:${SOCKS5_PORT}"
    else
      echo "代理创建失败，请检查自己输入的内容。"
    fi
  fi
}

########################梦开始的地方###########################

read -p "是否安装 socks5 (Y/N 回车N): " socks5choice
socks5choice=$(echo "${socks5choice}" | tr 'a-z' 'A-Z') # 转换为大写
if [ "$socks5choice" == "Y" ]; then
  # 检查socks5目录是否存在
  if [ -d "$FILE_PATH" ]; then
    install_socks5
  else
    # 创建socks5目录
    echo "正在创建 socks5 目录..."
    mkdir -p "$FILE_PATH"
    install_socks5
  fi
else
  echo "不安装 socks5"
fi

echo "脚本执行完成。致谢：RealNeoMan、k0baya、eooce"