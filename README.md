# Proxy Rules

个人自用代理规则和网络工具集 / Personal proxy rules and network utilities.

## 内容

### Surge Scripts
- `emby_redirect.js` - 基于路由器的 Emby URL 重定向
- `emby_redirect_ip.js` - 基于 WiFi SSID 的 Emby URL 重定向（支持 tvOS）

### Shell Scripts
- `tc_p2p.sh` - Linux 流量控制脚本，动态限制 P2P 上传带宽

## Surge 配置示例

```ini
[Script]
emby_redirect = type=http-request,pattern=^http://.*\.,script-path=emby_redirect.js,argument=<router>,<source>,<target>
```

参数说明:
- `router` - 内网路由器 IP
- `source` - 原始域名/地址
- `target` - 目标域名/地址

## tc_p2p.sh 使用说明

运行环境：Linux (需要 root 权限)

```bash
sudo ./tc_p2p.sh
```

功能:
- 监控 `eth0` 接口上传速度
- 超过 55 Mbps 时限制 qBittorrent 带宽至 5 Mbps
- 降至 15 Mbps 以下时恢复至 50 Mbps
- 使用 `tc` HTB qdisc 和 `fwmark` 流量分类
