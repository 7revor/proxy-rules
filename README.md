# proxy-rules

一个面向个人网络环境的规则仓库，主要用于 **Surge / Sub-Store / Sub-Converter** 场景：
- 维护常用分流规则（AI、媒体、PT、代理、直连）；
- 通过 `subconverter.min.ini` 统一生成订阅分组与策略组；
- 提供 Emby 局域网重定向脚本与 Linux `tc` 动态限速脚本。

> 适合「自建规则 + 远程托管 + 在多客户端复用」的使用方式。

---

## 仓库结构

- `subconverter.min.ini`：Sub-Converter 主配置模板，包含规则来源、策略组、地区分组。  
- `ai.list`：AI/开发工具相关分流规则（Claude、OpenAI、Cursor、Copilot 等）。  
- `proxy.list`：需要走代理的域名规则。  
- `direct_ip.list`：指定 IP 直连规则（CIDR）。  
- `media.list`：媒体相关分流规则（含 Emby/Jable 等）。  
- `pt.list`：PT 站点域名规则。  
- `emby_redirect.js`：按 Wi-Fi SSID 判断是否执行 URL 重定向（Surge 脚本）。  
- `emby_redirect_ip.js`：按网关 IP 判断是否执行 URL 重定向（Surge 脚本）。  
- `tc_p2p.sh`：Linux `tc` 动态上传限速脚本（根据上传速率自动收紧/恢复）。

---

## 功能概览

### 1) 规则分流

仓库内 `.list` 文件可直接作为远程规则源使用，按主题拆分：
- **AI**：大模型与开发辅助服务（OpenAI / Claude / Cursor / Copilot）；
- **媒体**：流媒体与视频站点；
- **代理**：需要科学上网的通用域名；
- **直连 IP**：对指定机器强制直连；
- **PT**：PT 站点域名集合。

### 2) Sub-Converter 模板

`subconverter.min.ini` 中已预置：
- 常用规则集来源（Blackmatrix7 + 本仓库）；
- 代理组（`🚀 科学上网`、`🤖 OpenAI`、`🎬 海外媒体` 等）；
- 地区节点自动筛选（香港/美国/日本/新加坡）；
- `FINAL` 兜底规则。

你可以把它作为你自己的基础模板，按需新增 ruleset 或策略组。

### 3) Emby 内外网重定向

提供两种判定方式：
- `emby_redirect.js`：按 **Wi-Fi SSID** 判断是否内网；
- `emby_redirect_ip.js`：按 **主路由 IP** 判断是否内网。

命中内网条件时，会把请求 URL 中的 `source` 替换为 `target`，实现同一客户端在内外网自动切换地址。

### 4) P2P 动态限速

`tc_p2p.sh` 用 `tc htb` + `fwmark` 做动态控制：
- 上传超过阈值后，P2P 类流量降速；
- 进入冷却期，防止频繁抖动；
- 上传恢复后自动回到正常限速。

适用于家庭宽带上行容易被 BT/QB 占满、影响延迟与其他业务的场景。

---

## 快速使用

### A. 作为远程规则集引用

以 GitHub Raw 为例（将 `7revor` 替换为你的用户名）：

- `https://raw.githubusercontent.com/7revor/proxy-rules/main/ai.list`
- `https://raw.githubusercontent.com/7revor/proxy-rules/main/proxy.list`
- `https://raw.githubusercontent.com/7revor/proxy-rules/main/media.list`
- `https://raw.githubusercontent.com/7revor/proxy-rules/main/pt.list`
- `https://raw.githubusercontent.com/7revor/proxy-rules/main/direct_ip.list`

### B. 在 Sub-Converter 中使用

1. 将 `subconverter.min.ini` 作为配置模板导入；
2. 根据你的机场节点命名习惯调整地区正则；
3. 按需求修改策略组（例如 OpenAI 强制走指定节点组）。

### C. Surge 重定向脚本参数

两个脚本均使用逗号参数：

- `emby_redirect.js`：`SSID,source,target`
- `emby_redirect_ip.js`：`router_ip,source,target`

示例：

```txt
HomeWiFi,https://emby.example.com,https://192.168.1.10:8096
```

---

## `tc_p2p.sh` 使用说明（Linux）

> 需要 root 权限，且系统已安装 `iproute2`（含 `tc`）。

1. 修改脚本顶部参数（网卡名、阈值、限速值等）；
2. 确保你的 P2P 流量已通过 `fwmark 1` 标记；
3. 运行脚本并观察日志输出。

建议先在低峰时段测试阈值，避免误伤正常上传业务。

---

## 自定义建议

- AI 规则：根据你实际使用的模型平台增删域名；
- 代理规则：仅保留实际命中的域名，减小规则体积；
- 媒体/PT 规则：按你的站点名单维护，避免无关域名；
- 策略组：将高优先业务（OpenAI、远程开发）单独成组。

---

## 免责声明

本仓库仅用于个人网络分流配置与学习交流，请遵守所在地区法律法规及各服务平台的使用条款。
