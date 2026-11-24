#!/bin/bash
# Derived from yonggekkk/argosbx V26.11.20; single VLESS TLS node edition.
export LANG=en_US.UTF-8
umask 077
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
SCRIPT_SOURCE="$(readlink -f "$SCRIPT_SOURCE" 2>/dev/null || printf '%s' "$SCRIPT_SOURCE")"

custom_configure() {
  local action="${1:-}" selection="${xhttp:-${argo:-ws}}" saved_mode="" selected_port=""
  local maintenance=no
  case "$action" in
    list|del|upx|upa|res) maintenance=yes ;;
    ups) echo "argo.sh使用Xray，请用upx更新内核。" >&2; return 1 ;;
    ""|ins|rep) ;;
    *) echo "用法：bash argo.sh [ins|rep|list|res|upx|upa|del]" >&2; return 1 ;;
  esac
  # Maintenance uses the installed transport and never asks for tunnel credentials again.
  if [ "$maintenance" = yes ] && [ -s "$HOME/agsbx/vlvm" ]; then
    IFS= read -r saved_mode < "$HOME/agsbx/vlvm"
    case "$saved_mode" in Vlessx) selection=xhttp ;; Vless) selection=ws ;; esac
  fi
  case "$selection" in
    1|y|Y|yes|YES|true|TRUE|on|ON|xhttp|vxpt) CUSTOM_XHTTP=yes ;;
    0|n|N|no|NO|false|FALSE|off|OFF|ws|vwpt) CUSTOM_XHTTP=no ;;
    *) echo "xhttp支持1/0（或yes/no）；默认0为WebSocket。" >&2; return 1 ;;
  esac
  agn="${agn:-${ARGO_DOMAIN:-}}"
  agk="${agk:-${ARGO_AUTH:-}}"
  uuid="${uuid:-${UUID:-}}"
  if [ "$maintenance" = no ]; then
    if [ "$CUSTOM_XHTTP" = yes ] && { [ -z "$agn" ] || [ -z "$agk" ]; }; then
      echo "XHTTP模式要求同时设置固定隧道域名agn和token agk；现有配置保持原样。" >&2
      return 1
    fi
    if { [ -n "$agn" ] && [ -z "$agk" ]; } || { [ -z "$agn" ] && [ -n "$agk" ]; }; then
      echo "固定隧道需同时设置agn和agk；两者都省略时使用临时隧道。" >&2
      return 1
    fi
    if [ -n "$agn" ] && ! [[ "$agn" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]; then
      echo "agn应填写域名，不含协议、端口、路径或空白。" >&2; return 1
    fi
    # Token is placed inside service-file quotes, not evaluated as shell code.
    case "$agk" in
      *[[:space:][:cntrl:]]*|*'"'*|*"'"*|*'`'*|*'$'*|*'\'*|*'%'*)
        echo "agk包含服务配置不接受的字符。" >&2; return 1 ;;
    esac
    if [ -n "$uuid" ] && ! [[ "$uuid" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
      echo "uuid应为标准UUID格式。" >&2; return 1
    fi
  fi
  if [ "$CUSTOM_XHTTP" = yes ]; then
    selected_port="${vxpt:-${ARGO_PORT:-${argo_pt:-}}}"
  else
    selected_port="${vwpt:-${ARGO_PORT:-${argo_pt:-}}}"
  fi
  if [ -n "$selected_port" ]; then
    if ! [[ "$selected_port" =~ ^[0-9]{1,5}$ ]] || (( 10#$selected_port < 1 || 10#$selected_port > 65535 )); then
      echo "回源端口应为1至65535的整数。" >&2; return 1
    fi
    selected_port=$((10#$selected_port))
  fi
  # Only the selected inbound may be enabled, including when invoked from an old environment.
  unset vlpt vmpt vwpt vxpt hypt tupt xhpt anpt arpt sspt sopt nvpt xupt xcpt snpt
  unset vlp vmp vwp vxp hyp tup xhp anp arp ssp sop nvp xup xcp snp vmag wap
  if [ "$CUSTOM_XHTTP" = yes ]; then
    export vxpt="$selected_port"; vxp=yes; argo=vxpt
  else
    export vwpt="$selected_port"; vwp=yes; argo=vwpt
  fi
  vmag=yes
  export uuid argo
  export port_vw="${vwpt:-}" port_vx="${vxpt:-}"
  export port_vl_re='' port_vm_ws='' port_hy2='' port_tu='' port_xh='' port_an='' port_ar=''
  export port_ss='' port_so='' port_nv='' port_xu='' port_xc='' port_sn=''
  export ym_vl_re='' cdnym=''
  export ARGO_DOMAIN="$agn" ARGO_AUTH="$agk" agqc="${agqc:-}"
  export ippz="${ippz:-}" warp="${warp:-}" name="${name:-}" oap="${oap:-}"
  [ -z "${warp+x}" ] || [ -z "$warp" ] || wap=yes
  return 0
}

custom_configure "${1:-}" || exit 1
# Install the same local edition for subsequent maintenance, rather than fetching upstream again.
case "${1:-}" in
  ""|ins|rep)
    if [ ! -f "$SCRIPT_SOURCE" ]; then
      echo "请先将argo.sh保存为本地文件，再用bash执行。" >&2; exit 1
    fi
    mkdir -p "$HOME/agsbx" || exit 1
    if [ ! "$SCRIPT_SOURCE" -ef "$HOME/agsbx/argo.sh" ]; then
      cp "$SCRIPT_SOURCE" "$HOME/agsbx/argo.sh" || exit 1
    fi
    ;;
esac
v46url="https://icanhazip.com"
agsbxurl="$HOME/agsbx/argo.sh"
showmode(){
echo "argo.sh：VLESS + WS/XHTTP + TLS 单节点（443）。"
echo "项目仓库：https://github.com/jy02739245/ssh_tools"
echo "下载脚本：curl -fL https://raw.githubusercontent.com/jy02739245/ssh_tools/main/argo.sh -o argo.sh"
echo "首次安装（默认临时WS）：bash ./argo.sh"
echo "切换XHTTP（请替换域名和Token）：xhttp=1 vxpt=54321 agn='YOUR_TUNNEL_DOMAIN' agk='YOUR_TUNNEL_TOKEN' bash \"$HOME/bin/agsbx\" rep"
echo "固定隧道需在Cloudflare设置HTTP回源：http://127.0.0.1:54321（与vxpt一致）"
echo "切回临时WS：xhttp=0 agn= agk= ARGO_DOMAIN= ARGO_AUTH= bash \"$HOME/bin/agsbx\" rep"
echo "查看节点：bash \"$HOME/bin/agsbx\" list；重启：bash \"$HOME/bin/agsbx\" res"
echo "更新Xray：bash \"$HOME/bin/agsbx\" upx；更新隧道：bash \"$HOME/bin/agsbx\" upa"
echo "卸载：bash \"$HOME/bin/agsbx\" del"
echo "rep会替换现有节点配置，请重新导入输出链接；日常list/res无需再次填写域名和Token。"
}

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "argo.sh — VLESS WS/XHTTP + TLS 单节点安装脚本"
echo "项目仓库：https://github.com/jy02739245/ssh_tools"
echo "基于 yonggekkk/argosbx 定制"
echo "当前版本：V26.11.20-custom-single-tls"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
hostname=$(uname -a | awk '{print $2}')
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
[ -z "$(systemd-detect-virt 2>/dev/null)" ] && vi=$(virt-what 2>/dev/null) || vi=$(systemd-detect-virt 2>/dev/null)
case $(uname -m) in
arm64|aarch64) cpu=arm64;;
amd64|x86_64) cpu=amd64;;
*) echo "目前脚本不支持$(uname -m)架构" && exit
esac
case "${1:-}" in
""|ins|rep)
if [ ! -f sbx_update ]; then
echo "执行必要的脚本依赖中，请稍等10秒……"
if command -v apk >/dev/null 2>&1; then
apk update >/dev/null 2>&1 && apk add --no-cache bash busybox-extras gcompat libc6-compat iptables openssl >/dev/null 2>&1
elif command -v apt >/dev/null 2>&1; then
export DEBIAN_FRONTEND=noninteractive
printf 'iptables-persistent iptables-persistent/autosave_v4 boolean true\niptables-persistent iptables-persistent/autosave_v6 boolean true\n' | debconf-set-selections
apt update >/dev/null 2>&1 && apt install -y busybox coreutils util-linux iptables iptables-persistent cron openssl >/dev/null 2>&1
fi
touch sbx_update
fi
;;
esac
v4v6(){
v4=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- "$v46url" 2>/dev/null) )
v6=$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 --tries=2 -qO- "$v46url" 2>/dev/null) )
#v4dq=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k https://myip.ipip.net/ | awk -F'来自于：' '{print $2}' 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- https://myip.ipip.net/ | awk -F'来自于：' '{print $2}' 2>/dev/null) )
v6dq=$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k https://ip.fm | sed -n 's/.*Location: //p' 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 --tries=2 -qO- https://ip.fm | grep '<span class="has-text-grey-light">Location:' | tail -n1 | sed -E 's/.*>Location: <\/span>([^<]+)<.*/\1/' 2>/dev/null) )
v4dq=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k https://ip.fm | sed -n 's/.*Location: //p' 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- https://ip.fm | grep '<span class="has-text-grey-light">Location:' | tail -n1 | sed -E 's/.*>Location: <\/span>([^<]+)<.*/\1/' 2>/dev/null) )
}
warpsx(){
warpurl=$( (command -v curl >/dev/null 2>&1 && curl -sm5 -k https://warp.xijp.eu.org 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget --tries=2 -qO- https://warp.xijp.eu.org 2>/dev/null) )
if [ -z "$warpurl" ] || printf '%s' "$warpurl" | grep -q html; then
wpv6='2606:4700:110:8d8d:1845:c39f:2dd5:a03a'
pvk='52cuYFgCJXp0LAq7+nWJIbCXXgU9eGggOc+Hlfz5u6A='
res='[215, 69, 233]'
else
pvk=$(echo "$warpurl" | awk -F'：' '/Private_key/{print $2}' | xargs)
wpv6=$(echo "$warpurl" | awk -F'：' '/IPV6/{print $2}' | xargs)
res=$(echo "$warpurl" | awk -F'：' '/reserved/{print $2}' | xargs)
fi
if [ -n "$name" ]; then
sxname=$name-
echo "$sxname" > "$HOME/agsbx/name"
echo
echo "所有节点名称前缀：$name"
fi
v4v6
if echo "$v6" | grep -q '^2a09' || echo "$v4" | grep -q '^104.28'; then
s1outtag=direct; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warpargo
echo; echo "请注意：你已安装了warp"
else
if [ "$wap" != yes ]; then
s1outtag=direct; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warpargo
else
case "$warp" in
""|sx|xs) s1outtag=warp-out; s2outtag=warp-out; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
s ) s1outtag=warp-out; s2outtag=warp-out; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
s4) s1outtag=warp-out; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"0.0.0.0/0"'; wap=warp ;;
s6) s1outtag=warp-out; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0"'; wap=warp ;;
x ) s1outtag=direct; s2outtag=direct; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
x4) s1outtag=direct; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
x6) s1outtag=direct; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
s4x4|x4s4) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"0.0.0.0/0"'; wap=warp ;;
s4x6|x6s4) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"0.0.0.0/0"'; wap=warp ;;
s6x4|x4s6) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0"'; wap=warp ;;
s6x6|x6s6) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"::/0"'; wap=warp ;;
sx4|x4s) s1outtag=warp-out; s2outtag=warp-out; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
sx6|x6s) s1outtag=warp-out; s2outtag=warp-out; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
xs4|s4x) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"0.0.0.0/0"'; wap=warp ;;
xs6|s6x) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"::/0"'; wap=warp ;;
* ) s1outtag=direct; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warpargo ;;
esac
fi
fi
case "$warp" in *x4*) wxryx='ForceIPv4' ;; *x6*) wxryx='ForceIPv6' ;; *) wxryx='ForceIPv6v4' ;; esac
if command -v curl >/dev/null 2>&1; then
curl -s4m5 -k "$v46url" >/dev/null 2>&1 && v4_ok=true
elif command -v wget >/dev/null 2>&1; then
timeout 3 wget -4 --tries=2 -qO- "$v46url" >/dev/null 2>&1 && v4_ok=true
fi
if command -v curl >/dev/null 2>&1; then
curl -s6m5 -k "$v46url" >/dev/null 2>&1 && v6_ok=true
elif command -v wget >/dev/null 2>&1; then
timeout 3 wget -6 --tries=2 -qO- "$v46url" >/dev/null 2>&1 && v6_ok=true
fi
if [ "$v4_ok" = true ] && [ "$v6_ok" = true ]; then
case "$warp" in *s4*) sbyx='prefer_ipv4' ;; *) sbyx='prefer_ipv6' ;; esac
case "$warp" in *x4*) xryx='ForceIPv4v6' ;; *x*) xryx='ForceIPv6v4' ;; *) xryx='ForceIPv6v4' ;; esac
elif [ "$v4_ok" = true ] && [ "$v6_ok" != true ]; then
case "$warp" in *s4*|x) sbyx='ipv4_only' ;; *) sbyx='prefer_ipv6' ;; esac
case "$warp" in *x4*) xryx='ForceIPv4' ;; *x*) xryx='ForceIPv6v4' ;; *) xryx='ForceIPv4v6' ;; esac
elif [ "$v4_ok" != true ] && [ "$v6_ok" = true ]; then
case "$warp" in *s6*|x) sbyx='ipv6_only' ;; *) sbyx='prefer_ipv4' ;; esac
case "$warp" in *x6*) xryx='ForceIPv6' ;; *x*) xryx='ForceIPv4v6' ;; *) xryx='ForceIPv6v4' ;; esac
fi
}
upxray(){
url="https://github.com/yonggekkk/argosbx/releases/download/argosbx/xray-$cpu"; out="$HOME/agsbx/xray"; (command -v curl >/dev/null 2>&1 && curl -Lo "$out" -# --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -O "$out" --tries=2 "$url")
chmod +x "$HOME/agsbx/xray"
sbcore=$("$HOME/agsbx/xray" version 2>/dev/null | awk '/^Xray/{print $2}')
echo "已安装Xray正式版内核：$sbcore"
}
upsingbox(){
url="https://github.com/yonggekkk/argosbx/releases/download/argosbx/sing-box-$cpu"; out="$HOME/agsbx/sing-box"; (command -v curl>/dev/null 2>&1 && curl -Lo "$out" -# --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -O "$out" --tries=2 "$url")
chmod +x "$HOME/agsbx/sing-box"
sbcore=$("$HOME/agsbx/sing-box" version 2>/dev/null | awk '/version/{print $NF}')
echo "已安装Sing-box正式版内核：$sbcore"
}
insuuid(){
if [ -z "$uuid" ] && [ ! -e "$HOME/agsbx/uuid" ]; then
uuid=$("$HOME/agsbx/xray" uuid) || return 1
echo "$uuid" > "$HOME/agsbx/uuid"
elif [ -n "$uuid" ]; then
echo "$uuid" > "$HOME/agsbx/uuid"
fi
uuid=$(cat "$HOME/agsbx/uuid")
echo "UUID密码：$uuid"
}
installxray(){
echo "=========启用Xray内核（单个VLESS入站）========="
if [ ! -x "$HOME/agsbx/xray" ]; then upxray || return 1; fi
insuuid || return 1
local transport="ws" suffix="vw" port_file="$HOME/agsbx/port_vw" local_port="$port_vw"
if [ "$CUSTOM_XHTTP" = yes ]; then
  transport=xhttp; suffix=vx; port_file="$HOME/agsbx/port_vx"; local_port="$port_vx"
fi
if [ -z "$local_port" ] && [ -s "$port_file" ]; then local_port=$(cat "$port_file"); fi
if [ -z "$local_port" ]; then local_port=$(shuf -i 10000-65535 -n 1); fi
if ! [[ "$local_port" =~ ^[0-9]{1,5}$ ]] || (( 10#$local_port < 1 || 10#$local_port > 65535 )); then
  echo "保存的回源端口无效，请指定vwpt或vxpt。" >&2; return 1
fi
local_port=$((10#$local_port))
printf '%s\n' "$local_port" > "$port_file"
if [ "$transport" = xhttp ]; then port_vx="$local_port"; else port_vw="$local_port"; fi
cat > "$HOME/agsbx/xr.json" <<EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {
      "tag": "vless-${transport}",
      "listen": "127.0.0.1",
      "port": ${local_port},
      "protocol": "vless",
      "settings": {"clients": [{"id": "${uuid}"}], "decryption": "none"},
      "streamSettings": {
        "network": "${transport}",
        "security": "none",
EOF
if [ "$transport" = xhttp ]; then
cat >> "$HOME/agsbx/xr.json" <<EOF
        "xhttpSettings": {"host": "", "path": "/${uuid}-${suffix}", "mode": "auto"}
EOF
else
cat >> "$HOME/agsbx/xr.json" <<EOF
        "wsSettings": {"path": "/${uuid}-${suffix}"}
EOF
fi
cat >> "$HOME/agsbx/xr.json" <<EOF
      }
    }
EOF
echo "VLESS ${transport} HTTP回源：http://127.0.0.1:${local_port}"
}

installsb(){
echo
echo "=========启用Sing-box内核========="
if [ ! -e "$HOME/agsbx/sing-box" ]; then
upsingbox
fi
cat > "$HOME/agsbx/sb.json" <<EOF
{
"log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
EOF
insuuid
if [ -s "/root/ygkkkca/private.key" ] && [ -n "$nvp" ]; then
nvp=nvpt
if [ -z "$port_nv" ] && [ ! -e "$HOME/agsbx/port_nv" ]; then
port_nv=$(shuf -i 10000-65535 -n 1)
echo "$port_nv" > "$HOME/agsbx/port_nv"
elif [ -n "$port_nv" ]; then
echo "$port_nv" > "$HOME/agsbx/port_nv"
fi
port_nv=$(cat "$HOME/agsbx/port_nv")
echo "Naiveproxy端口：$port_nv"
cat >> "$HOME/agsbx/sb.json" <<EOF
    {
        "type": "naive",
        "tag": "naive-sb",
        "listen": "::",
        "listen_port": ${port_nv},
        "users": [
            {
                "username": "${uuid}",
                "password": "${uuid}"
            }
        ],
        "tls": {
            "enabled": true,
            "certificate_path": "/root/ygkkkca/cert.crt",
            "key_path": "/root/ygkkkca/private.key"
        }
    },
EOF
else
nvp=nvptargo
fi

if [ -n "$tup" ]; then
tup=tupt
if [ -z "$port_tu" ] && [ ! -e "$HOME/agsbx/port_tu" ]; then
port_tu=$(shuf -i 10000-65535 -n 1)
echo "$port_tu" > "$HOME/agsbx/port_tu"
elif [ -n "$port_tu" ]; then
echo "$port_tu" > "$HOME/agsbx/port_tu"
fi
port_tu=$(cat "$HOME/agsbx/port_tu")
echo "Tuic端口：$port_tu"
cat >> "$HOME/agsbx/sb.json" <<EOF
        {
            "type":"tuic",
            "tag": "tuic5-sb",
            "listen": "::",
            "listen_port": ${port_tu},
            "users": [
                {
                    "uuid": "${uuid}",
                    "password": "${uuid}"
                }
            ],
            "congestion_control": "bbr",
            "tls":{
                "enabled": true,
                "alpn": [
                    "h3"
                ],
                "certificate_path": "$certificateHTA",
                "key_path": "$keyHTA"
            }
        },
EOF
else
tup=tuptargo
fi
if [ -n "$anp" ]; then
anp=anpt
if [ -z "$port_an" ] && [ ! -e "$HOME/agsbx/port_an" ]; then
port_an=$(shuf -i 10000-65535 -n 1)
echo "$port_an" > "$HOME/agsbx/port_an"
elif [ -n "$port_an" ]; then
echo "$port_an" > "$HOME/agsbx/port_an"
fi
port_an=$(cat "$HOME/agsbx/port_an")
echo "Anytls端口：$port_an"
cat >> "$HOME/agsbx/sb.json" <<EOF
        {
            "type":"anytls",
            "tag":"anytls-sb",
            "listen":"::",
            "listen_port":${port_an},
            "users":[
                {
                  "password":"${uuid}"
                }
            ],
            "padding_scheme":[],
            "tls":{
                "enabled": true,
                "certificate_path": "$certificateHTA",
                "key_path": "$keyHTA"
            }
        },
EOF
else
anp=anptargo
fi
if [ -n "$arp" ]; then
arp=arpt
if [ -z "$ym_vl_re" ]; then
ym_vl_re=apple.com
fi
echo "$ym_vl_re" > "$HOME/agsbx/ym_vl_re"
echo "Reality域名：$ym_vl_re"
mkdir -p "$HOME/agsbx/sbk"
if [ ! -e "$HOME/agsbx/sbk/private_key" ]; then
key_pair=$("$HOME/agsbx/sing-box" generate reality-keypair)
private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')
public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')
short_id=$("$HOME/agsbx/sing-box" generate rand --hex 4)
echo "$private_key" > "$HOME/agsbx/sbk/private_key"
echo "$public_key" > "$HOME/agsbx/sbk/public_key"
echo "$short_id" > "$HOME/agsbx/sbk/short_id"
fi
private_key_s=$(cat "$HOME/agsbx/sbk/private_key")
public_key_s=$(cat "$HOME/agsbx/sbk/public_key")
short_id_s=$(cat "$HOME/agsbx/sbk/short_id")
if [ -z "$port_ar" ] && [ ! -e "$HOME/agsbx/port_ar" ]; then
port_ar=$(shuf -i 10000-65535 -n 1)
echo "$port_ar" > "$HOME/agsbx/port_ar"
elif [ -n "$port_ar" ]; then
echo "$port_ar" > "$HOME/agsbx/port_ar"
fi
port_ar=$(cat "$HOME/agsbx/port_ar")
echo "Any-Reality端口：$port_ar"
cat >> "$HOME/agsbx/sb.json" <<EOF
        {
            "type":"anytls",
            "tag":"anyreality-sb",
            "listen":"::",
            "listen_port":${port_ar},
            "users":[
                {
                  "password":"${uuid}"
                }
            ],
            "padding_scheme":[],
            "tls": {
            "enabled": true,
            "server_name": "${ym_vl_re}",
             "reality": {
              "enabled": true,
              "handshake": {
              "server": "${ym_vl_re}",
              "server_port": 443
             },
             "private_key": "$private_key_s",
             "short_id": ["$short_id_s"]
            }
          }
        },
EOF
else
arp=arptargo
fi
if [ -n "$ssp" ]; then
ssp=sspt
if [ ! -e "$HOME/agsbx/sskey" ]; then
sskey=$("$HOME/agsbx/sing-box" generate rand 16 --base64)
echo "$sskey" > "$HOME/agsbx/sskey"
fi
if [ -z "$port_ss" ] && [ ! -e "$HOME/agsbx/port_ss" ]; then
port_ss=$(shuf -i 10000-65535 -n 1)
echo "$port_ss" > "$HOME/agsbx/port_ss"
elif [ -n "$port_ss" ]; then
echo "$port_ss" > "$HOME/agsbx/port_ss"
fi
sskey=$(cat "$HOME/agsbx/sskey")
port_ss=$(cat "$HOME/agsbx/port_ss")
echo "Shadowsocks-2022端口：$port_ss"
cat >> "$HOME/agsbx/sb.json" <<EOF
        {
            "type": "shadowsocks",
            "tag":"ss-2022",
            "listen": "::",
            "listen_port": $port_ss,
            "method": "2022-blake3-aes-128-gcm",
            "password": "$sskey"
    },  
EOF
else
ssp=ssptargo
fi
if [ -n "$snp" ]; then
snp=snpt
if [ -z "$port_sn" ] && [ ! -e "$HOME/agsbx/port_sn" ]; then
port_sn=$(shuf -i 10000-65535 -n 1)
echo "$port_sn" > "$HOME/agsbx/port_sn"
elif [ -n "$port_sn" ]; then
echo "$port_sn" > "$HOME/agsbx/port_sn"
fi
port_sn=$(cat "$HOME/agsbx/port_sn")
echo "Snell-V6端口：$port_sn"
cat >> "$HOME/agsbx/sb.json" <<EOF
        {
         "type": "snell",
         "tag": "snellv",
         "listen": "::",
         "listen_port": $port_sn,
         "version": 6,
         "psk": "$uuid",
         "mode": "default"
    },  
EOF
else
snp=snptargo
fi
}

xrsbhy2(){
if [ -n "$hyp" ]; then
hyp=hypt
if [ -z "$port_hy2" ] && [ ! -e "$HOME/agsbx/port_hy2" ]; then
port_hy2=$(shuf -i 10000-65535 -n 1)
echo "$port_hy2" > "$HOME/agsbx/port_hy2"
elif [ -n "$port_hy2" ]; then
echo "$port_hy2" > "$HOME/agsbx/port_hy2"
fi
port_hy2=$(cat "$HOME/agsbx/port_hy2")
echo "Hysteria2端口：$port_hy2"
if [ -e "$HOME/agsbx/xr.json" ]; then
cat >> "$HOME/agsbx/xr.json" <<EOF
    {
      "tag": "hy2-xr",
      "protocol": "hysteria",
      "port": ${port_hy2},
      "settings": {
        "version": 2,
        "clients": [
          {
            "auth": "${uuid}"
          }
        ]
      },
      "streamSettings": {
        "network": "hysteria",
        "security": "tls",
        "tlsSettings": {
		  "alpn": [
             "h3"
            ],
          "certificates": [
            {
              "certificateFile": "$certificateHTA",
              "keyFile": "$keyHTA"
            }
          ]
        }
      },
	   "sniffing": {
       "enabled": true,
       "destOverride": ["http", "tls", "quic"],
       "metadataOnly": false
       }
    },
EOF
else
cat >> "$HOME/agsbx/sb.json" <<EOF
    {
        "type": "hysteria2",
        "tag": "hy2-sb",
        "listen": "::",
        "listen_port": ${port_hy2},
        "users": [
            {
                "password": "${uuid}"
            }
        ],
        "ignore_client_bandwidth":false,
        "tls": {
            "enabled": true,
            "alpn": [
                "h3"
            ],
            "certificate_path": "$certificateHTA",
            "key_path": "$keyHTA"
        }
    },
EOF
fi
else
hyp=hyptargo
fi
}

xrsbvm(){
if [ -n "$vmp" ]; then
vmp=vmpt
if [ -z "$port_vm_ws" ] && [ ! -e "$HOME/agsbx/port_vm_ws" ]; then
port_vm_ws=$(shuf -i 10000-65535 -n 1)
echo "$port_vm_ws" > "$HOME/agsbx/port_vm_ws"
elif [ -n "$port_vm_ws" ]; then
echo "$port_vm_ws" > "$HOME/agsbx/port_vm_ws"
fi
port_vm_ws=$(cat "$HOME/agsbx/port_vm_ws")
echo "Vmess-ws端口：$port_vm_ws"
if [ -n "$cdnym" ]; then
echo "$cdnym" > "$HOME/agsbx/cdnym"
echo "80系CDN或者回源CDN的host域名 (确保IP已解析在CF域名)：$cdnym"
fi
if [ -e "$HOME/agsbx/xr.json" ]; then
cat >> "$HOME/agsbx/xr.json" <<EOF
        {
            "tag": "vmess-xr",
            "listen": "::",
            "port": ${port_vm_ws},
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "${uuid}"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                  "path": "${uuid}-vm"
            }
        },
            "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls", "quic"],
            "metadataOnly": false
            }
         }, 
EOF
else
cat >> "$HOME/agsbx/sb.json" <<EOF
{
        "type": "vmess",
        "tag": "vmess-sb",
        "listen": "::",
        "listen_port": ${port_vm_ws},
        "users": [
            {
                "uuid": "${uuid}",
                "alterId": 0
            }
        ],
        "transport": {
            "type": "ws",
            "path": "${uuid}-vm",
            "max_early_data":2048,
            "early_data_header_name": "Sec-WebSocket-Protocol"
        }
    },
EOF
fi
else
vmp=vmptargo
fi
}

xrsbso(){
if [ -n "$sop" ]; then
sop=sopt
if [ -z "$port_so" ] && [ ! -e "$HOME/agsbx/port_so" ]; then
port_so=$(shuf -i 10000-65535 -n 1)
echo "$port_so" > "$HOME/agsbx/port_so"
elif [ -n "$port_so" ]; then
echo "$port_so" > "$HOME/agsbx/port_so"
fi
port_so=$(cat "$HOME/agsbx/port_so")
echo "Socks5端口：$port_so"
if [ -e "$HOME/agsbx/xr.json" ]; then
cat >> "$HOME/agsbx/xr.json" <<EOF
        {
         "tag": "socks5-xr",
         "port": ${port_so},
         "listen": "::",
         "protocol": "socks",
         "settings": {
            "auth": "password",
             "accounts": [
               {
               "user": "${uuid}",
               "pass": "${uuid}"
               }
            ],
            "udp": true
          },
            "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls", "quic"],
            "metadataOnly": false
            }
         }, 
EOF
else
cat >> "$HOME/agsbx/sb.json" <<EOF
    {
      "tag": "socks5-sb",
      "type": "socks",
      "listen": "::",
      "listen_port": ${port_so},
      "users": [
      {
      "username": "${uuid}",
      "password": "${uuid}"
      }
     ]
    },
EOF
fi
else
sop=soptargo
fi
}

xrsbout(){
if [ -e "$HOME/agsbx/xr.json" ]; then
cat >> "$HOME/agsbx/xr.json" <<EOF
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct",
      "streamSettings": {
      "sockopt": {
      "domainStrategy": "${xryx}"
     }
  }
    },
    {
      "tag": "x-warp-out",
      "protocol": "wireguard",
      "settings": {
        "secretKey": "${pvk}",
        "address": [
          "172.16.0.2/32",
          "${wpv6}/128"
        ],
        "peers": [
          {
            "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
            "allowedIPs": [
              "0.0.0.0/0",
              "::/0"
            ],
            "endpoint": "${xendip}:2408"
          }
        ],
        "noKernelTun": true,
        "reserved": ${res}
        }
    },
    {
      "tag":"warp-out",
      "protocol":"freedom",
      "streamSettings": {
      "sockopt": {
      "domainStrategy": "${wxryx}",
      "dialerProxy": "x-warp-out"
    }
  }
}
  ],
  "routing": {
    "domainStrategy": "IPOnDemand",
    "rules": [
      {
        "type": "field",
        "ip": [ ${xip} ],
        "network": "tcp,udp",
        "outboundTag": "${x1outtag}"
      },
      {
        "type": "field",
        "network": "tcp,udp",
        "outboundTag": "${x2outtag}"
      }
    ]
  }
}
EOF
"$HOME/agsbx/xray" run -test -c "$HOME/agsbx/xr.json" || return 1
if pidof systemd >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/systemd/system/xr.service <<EOF
[Unit]
Description=xr service
After=network.target
[Service]
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=/root/agsbx/xray run -c /root/agsbx/xr.json
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload >/dev/null 2>&1
systemctl enable xr >/dev/null 2>&1
systemctl start xr >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/init.d/xray <<EOF
#!/sbin/openrc-run
description="xr service"
command="/root/agsbx/xray"
command_args="run -c /root/agsbx/xr.json"
command_background=yes
pidfile="/run/xray.pid"
command_background="yes"
depend() {
need net
}
EOF
chmod +x /etc/init.d/xray >/dev/null 2>&1
rc-update add xray default >/dev/null 2>&1
rc-service xray start >/dev/null 2>&1
else
nohup "$HOME/agsbx/xray" run -c "$HOME/agsbx/xr.json" >/dev/null 2>&1 &
fi
fi
}

custom_save_recovery(){
local xhttp="$CUSTOM_XHTTP" v
{
  for v in xhttp uuid agn agk agqc vwpt vxpt warp cfip sub subid subpt; do
    printf 'export %s=%q\n' "$v" "${!v}"
  done
} > "$HOME/agsbx/recover.env"
chmod 600 "$HOME/agsbx/recover.env"
}
ins(){
installxray || return 1
warpsx
xrsbout || return 1
if [ -n "$argo" ] && [ -n "$vmag" ]; then
echo
echo "=========启用Cloudflared-argo内核========="
if [ ! -e "$HOME/agsbx/cloudflared" ]; then
argocore=$({ command -v curl >/dev/null 2>&1 && curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared || wget -qO- https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared; } | grep -Eo '"[0-9.]+"' | sed -n 1p | tr -d '",')
echo "下载Cloudflared-argo最新正式版内核：$argocore"
url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu"; out="$HOME/agsbx/cloudflared"; (command -v curl>/dev/null 2>&1 && curl -Lo "$out" -# --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -O "$out" --tries=2 "$url")
chmod +x "$HOME/agsbx/cloudflared"
fi
cftupr=$([ -n "$agqc" ] && echo 'quic' || echo 'http2'); echo "$cftupr" > "$HOME/agsbx/cftupr.log"
if [ "$argo" = "vmpt" ]; then argoport=$(cat "$HOME/agsbx/port_vm_ws" 2>/dev/null); echo "Vmess" > "$HOME/agsbx/vlvm"; elif [ "$argo" = "vwpt" ]; then argoport=$(cat "$HOME/agsbx/port_vw" 2>/dev/null); echo "Vless" > "$HOME/agsbx/vlvm"; elif [ "$argo" = "vxpt" ]; then argoport=$(cat "$HOME/agsbx/port_vx" 2>/dev/null); echo "Vlessx" > "$HOME/agsbx/vlvm"; fi; echo "$argoport" > "$HOME/agsbx/argoport.log"
if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
argoname='固定'
if pidof systemd >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/systemd/system/argo.service <<EOF
[Unit]
Description=argo service
After=network.target
[Service]
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=/root/agsbx/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol $(cat $HOME/agsbx/cftupr.log 2>/dev/null) run --token "${ARGO_AUTH}"
Restart=on-failure
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload >/dev/null 2>&1
systemctl enable argo >/dev/null 2>&1
systemctl start argo >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/init.d/argo <<EOF
#!/sbin/openrc-run
description="argo service"
command="/root/agsbx/cloudflared"
command_args="tunnel --no-autoupdate --edge-ip-version auto --protocol $(cat $HOME/agsbx/cftupr.log 2>/dev/null) run --token ${ARGO_AUTH}"
pidfile="/run/argo.pid"
command_background="yes"
depend() {
need net
}
EOF
chmod +x /etc/init.d/argo >/dev/null 2>&1
rc-update add argo default >/dev/null 2>&1
rc-service argo start >/dev/null 2>&1
else
nohup "$HOME/agsbx/cloudflared" tunnel --no-autoupdate --edge-ip-version auto --protocol $(cat $HOME/agsbx/cftupr.log 2>/dev/null) run --token "${ARGO_AUTH}" >/dev/null 2>&1 &
fi
echo "${ARGO_DOMAIN}" > "$HOME/agsbx/sbargoym.log"
echo "${ARGO_AUTH}" > "$HOME/agsbx/sbargotoken.log"
else
argoname='临时'
nohup "$HOME/agsbx/cloudflared" tunnel --url http://127.0.0.1:$(cat $HOME/agsbx/argoport.log) --edge-ip-version auto --no-autoupdate --protocol $(cat $HOME/agsbx/cftupr.log 2>/dev/null) > $HOME/agsbx/argo.log 2>&1 &
fi
if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
argodomain="$ARGO_DOMAIN"
echo "固定隧道配置已写入；请在Cloudflare核对HTTP回源端口，并通过日志确认连接状态。"
else
echo "申请临时隧道域名……"
argodomain=$(custom_wait_tunnel) || return 1
echo "临时隧道域名已取得：$argodomain"
fi
fi
sleep 5
echo
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'agsbx/(s|x)' || pgrep -f 'agsbx/(s|x)' >/dev/null 2>&1 ; then
[ -f ~/.bashrc ] || touch ~/.bashrc
sed -i '/agsbx/d' ~/.bashrc
SCRIPT_PATH="$HOME/bin/agsbx"
mkdir -p "$HOME/bin"
cp "$agsbxurl" "$SCRIPT_PATH" || return 1
chmod +x "$SCRIPT_PATH"
if ! pidof systemd >/dev/null 2>&1 && ! command -v rc-service >/dev/null 2>&1; then
custom_save_recovery || return 1
printf 'if ! pgrep -f "agsbx/xray" >/dev/null 2>&1; then ( . %q; bash %q ); fi\n' "$HOME/agsbx/recover.env" "$HOME/bin/agsbx" >> ~/.bashrc
fi
sed -i '/export PATH="\$HOME\/bin:\$PATH"/d' ~/.bashrc
echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
grep -qxF 'source ~/.bashrc' ~/.bash_profile 2>/dev/null || echo 'source ~/.bashrc' >> ~/.bash_profile
. ~/.bashrc 2>/dev/null
crontab -l > /tmp/crontab.tmp 2>/dev/null
if ! pidof systemd >/dev/null 2>&1 && ! command -v rc-service >/dev/null 2>&1; then
sed -i '/agsbx\/sing-box/d' /tmp/crontab.tmp
sed -i '/agsbx\/xray/d' /tmp/crontab.tmp
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -q 'agsbx/s' || pgrep -f 'agsbx/s' >/dev/null 2>&1 ; then
echo '@reboot sleep 10 && /bin/sh -c "nohup $HOME/agsbx/sing-box run -c $HOME/agsbx/sb.json >/dev/null 2>&1 &"' >> /tmp/crontab.tmp
fi
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -q 'agsbx/x' || pgrep -f 'agsbx/x' >/dev/null 2>&1 ; then
echo '@reboot sleep 10 && /bin/sh -c "nohup $HOME/agsbx/xray run -c $HOME/agsbx/xr.json >/dev/null 2>&1 &"' >> /tmp/crontab.tmp
fi
fi
sed -i '/agsbx\/cloudflared/d' /tmp/crontab.tmp
if [ -n "$argo" ] && [ -n "$vmag" ]; then
if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
if ! pidof systemd >/dev/null 2>&1 && ! command -v rc-service >/dev/null 2>&1; then
echo '@reboot sleep 10 && /bin/sh -c "nohup $HOME/agsbx/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol $(cat $HOME/agsbx/cftupr.log 2>/dev/null) run --token $(cat $HOME/agsbx/sbargotoken.log 2>/dev/null) >/dev/null 2>&1 &"' >> /tmp/crontab.tmp
fi
else
if command -v apk >/dev/null 2>&1; then
cat > /etc/local.d/alpineargosbx.start <<EOF
#!/bin/bash
sleep 10
nohup $HOME/agsbx/cloudflared tunnel --url http://127.0.0.1:\$(cat $HOME/agsbx/argoport.log) --edge-ip-version auto --no-autoupdate --protocol $(cat $HOME/agsbx/cftupr.log 2>/dev/null) > $HOME/agsbx/argo.log 2>&1 &
sleep 10
HOME="$HOME" $HOME/bin/agsbx list >/dev/null 2>&1
EOF
chmod +x /etc/local.d/alpineargosbx.start
rc-update add local default >/dev/null 2>&1
else
echo '@reboot sleep 10 && /bin/bash -c "nohup $HOME/agsbx/cloudflared tunnel --url http://127.0.0.1:$(cat $HOME/agsbx/argoport.log) --edge-ip-version auto --no-autoupdate --protocol $(cat $HOME/agsbx/cftupr.log 2>/dev/null) > $HOME/agsbx/argo.log 2>&1 & sleep 10 && bash $HOME/bin/agsbx list >/dev/null 2>&1"' >> /tmp/crontab.tmp
fi
fi
fi
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
echo "argo.sh脚本进程启动成功，安装完毕" && sleep 2
else
echo "argo.sh脚本进程未启动，安装失败" && exit
fi
if [ -n "$cfip" ]; then
set -- $cfip
cdnip1="$1"
cdnip2="$2"
echo "$cdnip1" > "$HOME/agsbx/cdnip1"
echo "$cdnip2" > "$HOME/agsbx/cdnip2"
else
cdnip1=""
cdnip2=""
echo "$cdnip1" > "$HOME/agsbx/cdnip1"
echo "$cdnip2" > "$HOME/agsbx/cdnip2"
fi
}
argosbxstatus(){
echo "=========当前三大内核运行状态========="
procs=$(find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null)
if echo "$procs" | grep -Eq 'agsbx/s' || pgrep -f 'agsbx/s' >/dev/null 2>&1; then
echo "Sing-box (版本V$("$HOME/agsbx/sing-box" version 2>/dev/null | awk '/version/{print $NF}'))：运行中"
else
echo "Sing-box：未启用"
fi
if echo "$procs" | grep -Eq 'agsbx/x' || pgrep -f 'agsbx/x' >/dev/null 2>&1; then
echo "Xray (版本V$("$HOME/agsbx/xray" version 2>/dev/null | awk '/^Xray/{print $2}'))：运行中"
else
echo "Xray：未启用"
fi
if echo "$procs" | grep -Eq 'agsbx/c' || pgrep -f 'agsbx/c' >/dev/null 2>&1; then
echo "Argo (版本V$("$HOME/agsbx/cloudflared" version 2>/dev/null | awk '{print $3}'))：运行中"
else
echo "Argo：未启用"
fi
}
custom_tunnel_domain(){
if [ -s "$HOME/agsbx/sbargoym.log" ]; then
  cat "$HOME/agsbx/sbargoym.log"
else
  LC_ALL=C grep -aoE 'https://[a-z0-9-]+\.trycloudflare\.com' "$HOME/agsbx/argo.log" 2>/dev/null | head -n 1 | cut -d/ -f3
fi
}
custom_wait_tunnel(){
local attempt domain
for ((attempt=0; attempt<30; attempt++)); do
  domain=$(custom_tunnel_domain)
  if [ -n "$domain" ]; then printf '%s\n' "$domain"; return 0; fi
  sleep 1
done
echo "30秒内尚未取得临时域名，请检查$HOME/agsbx/argo.log后运行list重试。" >&2
return 1
}
cip(){
local transport=ws suffix=vw saved_mode domain address node_uuid node_name link
saved_mode=$(cat "$HOME/agsbx/vlvm" 2>/dev/null)
case "$saved_mode" in
  Vlessx) transport=xhttp; suffix=vx ;;
  Vless) ;;
  *) echo "尚未找到argo.sh的WS/XHTTP节点配置。" >&2; return 1 ;;
esac
domain=$(custom_tunnel_domain)
node_uuid=$(cat "$HOME/agsbx/uuid" 2>/dev/null)
if [ -z "$domain" ] || [ -z "$node_uuid" ]; then
  echo "节点配置或隧道域名尚未就绪，请查看Xray和cloudflared日志。" >&2; return 1
fi
# Export one TLS node only; address, Host and SNI all default to the tunnel domain.
address=$(cat "$HOME/agsbx/cdnip1" 2>/dev/null)
address="${address:-$domain}"
node_name="vless-${transport}-tls-argo"
link="vless://${node_uuid}@${address}:443?encryption=none&type=${transport}&host=${domain}&path=%2F${node_uuid}-${suffix}&security=tls&sni=${domain}&fp=chrome"
[ "$transport" != xhttp ] || link="${link}&mode=auto"
link="${link}#${node_name}"
printf '%s\n' "$link" > "$HOME/agsbx/jhsub.txt"
cat > "$HOME/agsbx/clmi.yaml" <<EOF
mixed-port: 7890
allow-lan: false
mode: rule
log-level: warning
proxies:
  - name: "${node_name}"
    type: vless
    server: "${address}"
    port: 443
    uuid: "${node_uuid}"
    udp: true
    tls: true
    servername: "${domain}"
    skip-cert-verify: false
    client-fingerprint: chrome
    network: ${transport}
EOF
if [ "$transport" = xhttp ]; then
cat >> "$HOME/agsbx/clmi.yaml" <<EOF
    xhttp-opts:
      path: "/${node_uuid}-${suffix}"
      host: "${domain}"
      mode: auto
EOF
# Standard sing-box has no matching XHTTP transport; remove only a stale client export.
rm -f "$HOME/agsbx/sbox.json"
else
cat >> "$HOME/agsbx/clmi.yaml" <<EOF
    ws-opts:
      path: "/${node_uuid}-${suffix}"
      headers:
        Host: "${domain}"
EOF
cat > "$HOME/agsbx/sbox.json" <<EOF
{
  "inbounds": [{"type": "mixed", "listen": "127.0.0.1", "listen_port": 7890}],
  "outbounds": [{
    "type": "vless", "tag": "${node_name}", "server": "${address}", "server_port": 443,
    "uuid": "${node_uuid}",
    "tls": {"enabled": true, "server_name": "${domain}", "insecure": false},
    "transport": {"type": "ws", "path": "/${node_uuid}-${suffix}", "headers": {"Host": "${domain}"}}
  }]
}
EOF
fi
cat >> "$HOME/agsbx/clmi.yaml" <<EOF
proxy-groups:
  - name: PROXY
    type: select
    proxies: ["${node_name}"]
rules:
  - MATCH,PROXY
EOF
echo "单节点：VLESS + ${transport} + TLS（443）"
echo "隧道域名：$domain"
echo "本机HTTP回源端口：$(cat "$HOME/agsbx/argoport.log" 2>/dev/null)"
echo "$link"
if [ -s "$HOME/agsbx/subport.log" ]; then
  echo "单节点订阅端口：$(cat "$HOME/agsbx/subport.log")；节点列表：jhsub.txt；Mihomo配置：clmi.yaml"
  [ "$transport" != ws ] || echo "Sing-box配置：sbox.json"
fi
showmode
}

cleandel(){
for P in /proc/[0-9]*; do if [ -L "$P/exe" ]; then TARGET=$(readlink -f "$P/exe" 2>/dev/null); if echo "$TARGET" | grep -qE '/agsbx/c|/agsbx/s|/agsbx/x'; then PID=$(basename "$P"); kill "$PID" 2>/dev/null; fi; fi; done
kill -15 $(pgrep -f 'agsbx/s' 2>/dev/null) $(pgrep -f 'agsbx/c' 2>/dev/null) $(pgrep -f 'agsbx/x' 2>/dev/null) $(pgrep -f 'websbx' 2>/dev/null) >/dev/null 2>&1
sed -i '/agsbx/d' ~/.bashrc
sed -i '/export PATH="\$HOME\/bin:\$PATH"/d' ~/.bashrc
. ~/.bashrc 2>/dev/null
crontab -l > /tmp/crontab.tmp 2>/dev/null
sed -i '/agsbx\/sing-box/d' /tmp/crontab.tmp
sed -i '/agsbx\/xray/d' /tmp/crontab.tmp
sed -i '/agsbx\/cloudflared/d' /tmp/crontab.tmp
sed -i '/websbx/d' /tmp/crontab.tmp
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
rm -rf  "$HOME/bin/agsbx"
if pidof systemd >/dev/null 2>&1; then
for svc in xr sb argo; do
systemctl stop "$svc" >/dev/null 2>&1
systemctl disable "$svc" >/dev/null 2>&1
done
rm -rf /etc/systemd/system/{xr.service,sb.service,argo.service}
elif command -v rc-service >/dev/null 2>&1; then
for svc in sing-box xray argo; do
rc-service "$svc" stop >/dev/null 2>&1
rc-update del "$svc" default >/dev/null 2>&1
done
rm -rf /etc/init.d/{sing-box,xray,argo} /etc/local.d/alpineargosbx.start /etc/local.d/alpinesubsbx.start
netfilter-persistent save >/dev/null 2>&1
rc-service iptables save >/dev/null 2>&1
rc-service ip6tables save >/dev/null 2>&1
fi
}
xrestart(){
kill -15 $(pgrep -f 'agsbx/x' 2>/dev/null) >/dev/null 2>&1
if pidof systemd >/dev/null 2>&1; then
systemctl restart xr >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1; then
rc-service xray restart >/dev/null 2>&1
else
nohup $HOME/agsbx/xray run -c $HOME/agsbx/xr.json >/dev/null 2>&1 &
fi
}
custom_restart_tunnel(){
local protocol token port
protocol=$(cat "$HOME/agsbx/cftupr.log" 2>/dev/null)
protocol="${protocol:-http2}"
if [ -s "$HOME/agsbx/sbargotoken.log" ]; then
  token=$(cat "$HOME/agsbx/sbargotoken.log") || return 1
  if pidof systemd >/dev/null 2>&1; then
    systemctl restart argo >/dev/null 2>&1 || return 1
  elif command -v rc-service >/dev/null 2>&1; then
    rc-service argo restart >/dev/null 2>&1 || return 1
  else
    kill -15 $(pgrep -f 'agsbx/c' 2>/dev/null) >/dev/null 2>&1
    nohup "$HOME/agsbx/cloudflared" tunnel --no-autoupdate --edge-ip-version auto --protocol "$protocol" run --token "$token" >/dev/null 2>&1 &
  fi
else
  port=$(cat "$HOME/agsbx/argoport.log" 2>/dev/null) || return 1
  if ! [[ "$port" =~ ^[0-9]{1,5}$ ]] || (( 10#$port < 1 || 10#$port > 65535 )); then
    echo "保存的回源端口无效，请先使用rep重新配置。" >&2; return 1
  fi
  kill -15 $(pgrep -f 'agsbx/c' 2>/dev/null) >/dev/null 2>&1
  # Discard the previous quick-tunnel URL before waiting for the new connector.
  : > "$HOME/agsbx/argo.log" || return 1
  nohup "$HOME/agsbx/cloudflared" tunnel --url "http://127.0.0.1:$((10#$port))" --edge-ip-version auto --no-autoupdate --protocol "$protocol" > "$HOME/agsbx/argo.log" 2>&1 &
  custom_wait_tunnel >/dev/null || return 1
fi
return 0
}
sbrestart(){
kill -15 $(pgrep -f 'agsbx/s' 2>/dev/null) >/dev/null 2>&1
if pidof systemd >/dev/null 2>&1; then
systemctl restart sb >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1; then
rc-service sing-box restart >/dev/null 2>&1
else
nohup $HOME/agsbx/sing-box run -c $HOME/agsbx/sb.json >/dev/null 2>&1 &
fi
}
if [ "$1" = "del" ]; then
cleandel
rm -rf sbx_update "$HOME/agsbx" "$HOME/websbx"
echo "卸载完成"
echo "argo.sh 项目仓库：https://github.com/jy02739245/ssh_tools" && sleep 2
echo
showmode
exit
elif [ "$1" = "rep" ]; then
cleandel
rm -rf "$HOME/agsbx"/{sb.json,xr.json,sbargoym.log,sbargotoken.log,argo.log,argoport.log,cdnym,name}
echo "argo.sh重置协议完成，开始更新相关协议变量……" && sleep 2
echo
elif [ "$1" = "list" ]; then
cip
exit
elif [ "$1" = "upx" ]; then
for P in /proc/[0-9]*; do [ -L "$P/exe" ] || continue; TARGET=$(readlink -f "$P/exe" 2>/dev/null) || continue; case "$TARGET" in *"/agsbx/x"*) kill "$(basename "$P")" 2>/dev/null ;; esac; done
kill -15 $(pgrep -f 'agsbx/x' 2>/dev/null) >/dev/null 2>&1
upxray && xrestart && echo "Xray内核更新完成" && sleep 2 && cip
exit
elif [ "$1" = "ups" ]; then
for P in /proc/[0-9]*; do [ -L "$P/exe" ] || continue; TARGET=$(readlink -f "$P/exe" 2>/dev/null) || continue; case "$TARGET" in *"/agsbx/s"*) kill "$(basename "$P")" 2>/dev/null ;; esac; done
kill -15 $(pgrep -f 'agsbx/s' 2>/dev/null) >/dev/null 2>&1
upsingbox && sbrestart && echo "Sing-box内核更新完成" && sleep 2 && cip
exit
elif [ "$1" = "upa" ]; then
for P in /proc/[0-9]*; do [ -L "$P/exe" ] || continue; TARGET=$(readlink -f "$P/exe" 2>/dev/null) || continue; case "$TARGET" in *"/agsbx/c"*) kill "$(basename "$P")" 2>/dev/null ;; esac; done
kill -15 $(pgrep -f 'agsbx/c' 2>/dev/null) >/dev/null 2>&1
argocore=$({ command -v curl >/dev/null 2>&1 && curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared || wget -qO- https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared; } | grep -Eo '"[0-9.]+"' | sed -n 1p | tr -d '",')
echo "下载Cloudflared-argo最新正式版内核：$argocore"
url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu"; out="$HOME/agsbx/cloudflared"; (command -v curl>/dev/null 2>&1 && curl -Lo "$out" -# --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -O "$out" --tries=2 "$url")
chmod +x "$HOME/agsbx/cloudflared"
custom_restart_tunnel || exit 1
echo "Cloudflared-argo内核更新完成" && sleep 2 && cip
exit
elif [ "$1" = "res" ]; then
if [ ! -s "$HOME/agsbx/xr.json" ] || [ ! -x "$HOME/agsbx/xray" ] || [ ! -x "$HOME/agsbx/cloudflared" ] || [ ! -s "$HOME/agsbx/argoport.log" ]; then
  echo "尚未找到完整的安装配置，请先安装或使用rep重新配置。" >&2; exit 1
fi
# Restart from installed state even when either process has already exited.
xrestart || exit 1
custom_restart_tunnel || exit 1
echo "重启完成"
cip
exit
fi
if ! find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'agsbx/(s|x)' && ! pgrep -f 'agsbx/(s|x)' >/dev/null 2>&1; then
for P in /proc/[0-9]*; do if [ -L "$P/exe" ]; then TARGET=$(readlink -f "$P/exe" 2>/dev/null); if echo "$TARGET" | grep -qE '/agsbx/c|/agsbx/s|/agsbx/x'; then PID=$(basename "$P"); kill "$PID" 2>/dev/null && echo "Killed $PID ($TARGET)" || echo "Could not kill $PID ($TARGET)"; fi; fi; done
kill -15 $(pgrep -f 'agsbx/s' 2>/dev/null) $(pgrep -f 'agsbx/c' 2>/dev/null) $(pgrep -f 'agsbx/x' 2>/dev/null) >/dev/null 2>&1
if [ -z "$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 -qO- --tries=2 "$v46url" 2>/dev/null) )" ]; then
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1" > /etc/resolv.conf
fi
if [ -n "$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 -qO- --tries=2 "$v46url" 2>/dev/null) )" ]; then
sendip="2606:4700:d0::a29f:c001"
xendip="[2606:4700:d0::a29f:c001]"
else
sendip="162.159.192.1"
xendip="162.159.192.1"
fi
echo "VPS系统：$op"
echo "CPU架构：$cpu"
echo "argo.sh脚本未安装，开始安装…………" && sleep 1
if [ -n "$oap" ]; then
setenforce 0 >/dev/null 2>&1
iptables -P INPUT ACCEPT >/dev/null 2>&1
iptables -P FORWARD ACCEPT >/dev/null 2>&1
iptables -P OUTPUT ACCEPT >/dev/null 2>&1
iptables -F >/dev/null 2>&1
netfilter-persistent save >/dev/null 2>&1
echo
echo "iptables执行开放所有端口"
fi
# Public TLS terminates at Cloudflare; the trusted loopback origin is HTTP.
ins || exit 1
if [ -n "$sub" ]; then
subtokenipsub(){
if [ -z "$subid" ]; then
subtoken="$(cat "$HOME/agsbx/uuid")"
else
subtoken="$subid"
fi
rm -rf $HOME/websbx/"$(cat $HOME/agsbx/subtoken.log 2>/dev/null)"
echo $subtoken > $HOME/agsbx/subtoken.log
}
subportipsub(){
if [ -z "$subpt" ]; then
if [ -n "$(cat "$HOME/agsbx/subport.log" 2>/dev/null)" ]; then
subport=$(cat $HOME/agsbx/subport.log)
else
subport=$(shuf -i 10000-65535 -n 1)
fi
else
subport="$subpt"
fi
echo $subport > $HOME/agsbx/subport.log
}
subtokenipsub && subportipsub
echo "请稍后…………"
kill -15 $(pgrep -f 'websbx' 2>/dev/null) >/dev/null 2>&1
mkdir -p $HOME/websbx/"$(cat $HOME/agsbx/subtoken.log 2>/dev/null)"
ln -sf $HOME/agsbx/clmi.yaml $HOME/websbx/"$(cat $HOME/agsbx/subtoken.log 2>/dev/null)"/clmi.yaml
if [ "$CUSTOM_XHTTP" != yes ]; then
ln -sf $HOME/agsbx/sbox.json $HOME/websbx/"$(cat $HOME/agsbx/subtoken.log 2>/dev/null)"/sbox.json
fi
ln -sf $HOME/agsbx/jhsub.txt $HOME/websbx/"$(cat $HOME/agsbx/subtoken.log 2>/dev/null)"/jhsub.txt
if command -v apk >/dev/null 2>&1; then
busybox-extras httpd -f -p "$(cat $HOME/agsbx/subport.log 2>/dev/null)" -h $HOME/websbx > /dev/null 2>&1 &
else
busybox httpd -f -p "$(cat $HOME/agsbx/subport.log 2>/dev/null)" -h $HOME/websbx > /dev/null 2>&1 &
fi
sleep 5
if command -v apk >/dev/null 2>&1; then
cat > /etc/local.d/alpinesubsbx.start <<EOF
#!/bin/bash
sleep 10
busybox-extras httpd -f -p \$(cat $HOME/agsbx/subport.log 2>/dev/null) -h $HOME/websbx > /dev/null 2>&1 &
EOF
chmod +x /etc/local.d/alpinesubsbx.start
rc-update add local default >/dev/null 2>&1
else
crontab -l 2>/dev/null > /tmp/crontab.tmp
sed -i '/websbx/d' /tmp/crontab.tmp
echo '@reboot sleep 10 && /bin/bash -c "busybox httpd -f -p $(cat $HOME/agsbx/subport.log 2>/dev/null) -h $HOME/websbx > /dev/null 2>&1 &"' >> /tmp/crontab.tmp
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
fi
echo "本地IP订阅链接已更新完成"
fi
if [ -n "$hyjpt" ] && [ -n "$hyp" ]; then
echo
echo "设置Hysteria2协议的跳跃端口：$hyjpt"
iptables -t nat -F PREROUTING >/dev/null 2>&1
ip6tables -t nat -F PREROUTING >/dev/null 2>&1
hyport=$(cat "$HOME/agsbx/port_hy2")
for port in $hyjpt; do
iptables -t nat -A PREROUTING -p udp --dport "$port" -j DNAT --to-destination :$hyport
ip6tables -t nat -A PREROUTING -p udp --dport "$port" -j DNAT --to-destination :$hyport
done
netfilter-persistent save >/dev/null 2>&1
if command -v rc-service >/dev/null 2>&1 && command -v rc-update >/dev/null 2>&1; then
rc-update show default 2>/dev/null | grep -q 'iptables' || rc-update add iptables >/dev/null 2>&1
rc-update show default 2>/dev/null | grep -q 'ip6tables' || rc-update add ip6tables >/dev/null 2>&1
rc-service iptables save >/dev/null 2>&1
rc-service ip6tables save >/dev/null 2>&1
fi
fi
cip || exit 1
echo
else
echo "argo.sh脚本已安装"
echo
argosbxstatus
echo
echo "相关快捷方式如下："
showmode
exit
fi
