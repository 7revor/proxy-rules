#!/bin/sh

# 配置参数
INTERFACE="eth0"               # 网卡接口名称
HTB_DEFAULT_RATE="1000mbit"    # 默认根队列带宽
THRESHOLD_START=$((55 * 1024)) # 上传速度阈值（开始），55 Mbps
THRESHOLD_END=$((15 * 1024))   # 上传速度阈值（结束），15 Mbps
MAX_RATE_MBPS="50mbit"         # 正常状态下的最大带宽
LIMIT_RATE="5mbit"             # 限速带宽
COOLDOWN_TIME=60               # 限速后冷却时间（秒）
SLEEP_TIME=2                   # 检查间隔（秒）
P2P_CLASS_ID="1:10"            # QB带宽类 ID

# 全局状态变量
LAST_UP=0    # 上次上传字节数
LAST_TIME=0  # 上次检测时间戳
COOLDOWN=0   # 剩余冷却时间
IS_LIMITED=0 # 当前是否限速 (0/1)

# 日志函数
log() {
  local level=$1
  local message=$2
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

# 初始化网络接口检查
initialize_interface() {
  local max_retry=5
  local retry=0
  while [ $retry -lt $max_retry ]; do
    if ip link show dev "$INTERFACE" >/dev/null 2>&1; then
      if ip link show dev "$INTERFACE" | grep -q "state UP"; then
        log "INFO" "网络接口 $INTERFACE 已启用."
        return 0
      else
        log "WARN" "网络接口 $INTERFACE 存在但未启用，等待 2 秒..."
        sleep 2
        retry=$((retry + 1))
      fi
    else
      log "ERROR" "网络接口 $INTERFACE 未找到，退出脚本."
      exit 1
    fi
  done
  log "ERROR" "网络接口 $INTERFACE 初始化超时，退出脚本."
  exit 1
}

# 初始化TC规则
initialize_tc() {
  # 清除现有队列规则（忽略错误）
  tc qdisc del dev "$INTERFACE" root 2>/dev/null || true

  # 创建 HTB 根队列，默认流量走 1:1（不受限）
  tc qdisc add dev "$INTERFACE" root handle 1: htb default 1

  # 根类（总带宽 1000mbit）
  tc class add dev "$INTERFACE" parent 1: classid 1:1 htb rate "$HTB_DEFAULT_RATE" ceil "$HTB_DEFAULT_RATE"
  # 为默认流量类添加 fq_codel
  tc qdisc add dev "$INTERFACE" parent 1:1 fq_codel

  # 限速带宽类（使用 sfq）
  tc class add dev "$INTERFACE" parent 1:1 classid "$P2P_CLASS_ID" htb rate "$MAX_RATE_MBPS" ceil "$MAX_RATE_MBPS"
  # tc qdisc add dev "$INTERFACE" parent "$P2P_CLASS_ID" sfq

  # 添加过滤器（基于 fwmark 1 匹配 QB 流量到正常类）
  tc filter add dev "$INTERFACE" parent 1: protocol ip prio 1 handle 1 fw flowid "$P2P_CLASS_ID"

  log "INFO" "TC 初始化完成：根带宽 $HTB_DEFAULT_RATE，QB 初始带宽 $MAX_RATE_MBPS."
}

# 获取当前上传字节数
get_current_upload() {
  awk -v intf="$INTERFACE:" '$0 ~ intf {print $10}' /proc/net/dev
}

# 主循环
main_loop() {
  while true; do
    # 获取当前上传字节数
    CURRENT_UP=$(get_current_upload)
    if [ -z "$CURRENT_UP" ]; then
      log "ERROR" "无法读取 /proc/net/dev 中的流量数据."
      sleep "$SLEEP_TIME"
      continue
    fi

    # 获取当前时间
    CURRENT_TIME=$(date +%s)

    # 计算时间间隔（单位：秒）
    if [ "$LAST_TIME" -eq 0 ]; then
      # 首次运行，初始化 LAST_UP 和 LAST_TIME
      LAST_UP=$CURRENT_UP
      LAST_TIME=$CURRENT_TIME
      log "INFO" "初始化流量基准: LAST_UP=$LAST_UP, LAST_TIME=$LAST_TIME."
      sleep "$SLEEP_TIME"
      continue
    fi

    TIME_INTERVAL=$((CURRENT_TIME - LAST_TIME))

    # 计算上传速度（单位：kbps）
    if [ "$TIME_INTERVAL" -gt 0 ]; then
      UP_SPEED=$(((CURRENT_UP - LAST_UP) * 8 / TIME_INTERVAL / 1024))
      # log "INFO" "当前上传速度: ${UP_SPEED}kbps (${UP_SPEED} / 8 = $((UP_SPEED / 8)) kB/s)."
    else
      UP_SPEED=0
      # log "WARN" "时间间隔为0，跳过速度计算."
    fi

    # 更新状态
    LAST_UP=$CURRENT_UP
    LAST_TIME=$CURRENT_TIME

    # 动态阈值计算
    if [ "$IS_LIMITED" -eq 0 ]; then
      CURRENT_THRESHOLD=$THRESHOLD_START # 未限速时使用55mbps阈值
    else
      CURRENT_THRESHOLD=$THRESHOLD_END # 限速时使用10mbps阈值
    fi

    # 判断是否处于冷却时间
    if [ "$COOLDOWN" -gt 0 ]; then
      # 减少冷却时间
      COOLDOWN=$((COOLDOWN - TIME_INTERVAL))
      if [ "$COOLDOWN" -lt 0 ]; then
        COOLDOWN=0
      fi
      # 如果上传速度超过阈值，重置冷却时间
      if [ "$UP_SPEED" -gt "$CURRENT_THRESHOLD" ]; then
        COOLDOWN=$COOLDOWN_TIME
        # log "INFO" "上传速度超限 (${UP_SPEED}kbps > ${CURRENT_THRESHOLD}kbps)，重置冷却时间为 ${COOLDOWN} 秒."
      fi
      # log "INFO" "冷却剩余: ${COOLDOWN}秒，跳过限速检查."
    else
      # 不在冷却时间，检查上传速度
      if [ "$UP_SPEED" -gt "$CURRENT_THRESHOLD" ]; then
        # 仅在未限速时触发限速
        if [ "$IS_LIMITED" -eq 0 ]; then
          tc class change dev "$INTERFACE" parent 1:1 classid "$P2P_CLASS_ID" htb rate $LIMIT_RATE ceil $LIMIT_RATE
          log "WARN" "上传速度超限 (${UP_SPEED}kbps > ${CURRENT_THRESHOLD}kbps)，QB 流量已限速到 $LIMIT_RATE."
          IS_LIMITED=1
          COOLDOWN=$COOLDOWN_TIME
        fi
      else
        # 恢复正常带宽
        if [ "$IS_LIMITED" -eq 1 ]; then
          tc class change dev "$INTERFACE" parent 1:1 classid "$P2P_CLASS_ID" htb rate $MAX_RATE_MBPS ceil $MAX_RATE_MBPS
          log "WARN" "上传速度恢复正常，QB 流量已恢复到 $MAX_RATE_MBPS."
          IS_LIMITED=0
          COOLDOWN=0
        fi
      fi
    fi

    # 睡眠
    sleep "$SLEEP_TIME"
  done
}

# 主程序入口
initialize_interface
initialize_tc
main_loop
