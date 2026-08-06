#!/bin/bash

# network_traffic.sh [-t POLLING_INTERVAL] [NETWORK_INTERFACE...]

isecs=1
: ${rate_max:=1000000}

exit_err() {
  printf '{"text": "⚠ %s", "tooltip": "%s", "class": "error"}\n' "$1" "$2"
  exit 1
}

while getopts "t:" opt; do
  case $opt in
    t) isecs="$OPTARG" ;;
    *) exit_err "Args" "Invalid option" ;;
  esac
done
shift $((OPTIND - 1))

if test "${isecs}" -lt 1 2>/dev/null; then
  exit_err "${isecs}" "${isecs} is not a valid polling interval"
fi

declare -A is_target_iface
if [ $# -gt 0 ]; then
  for iface in "$@"; do
    test -h "/sys/class/net/${iface}" || exit_err "${iface}" "${iface} is not an existing network interface name"
    is_target_iface["$iface"]=1
  done
else
  for sys_iface in /sys/class/net/*; do
    iface="${sys_iface##*/}"
    [[ "$iface" != "lo" && "$iface" != "*" ]] && is_target_iface["$iface"]=1
  done
fi

# 1. 预先初始化文件描述符，避免在 snore 循环中重复创建
exec {_snore_fd}<> <(:) 2>/dev/null
snore() {
  local IFS
  read ${1:+-t "$1"} -u $_snore_fd || :
}

# 2. 零子进程（Zero-Subshell）单位格式化函数
# 参数 1: 字节数数值，参数 2: 接收输出结果的变量名（使用 printf -v 避免 $(...) 子进程）
human_readable() {
  local val=${1:-0}
  local var_name=$2
  if (( val <= 0 )); then
    printf -v "$var_name" "0B"
    return
  fi
  local hrunits=( B K M G T P )
  local ndigits=${#val}
  local idxunit=$(( (2 + ndigits) / 3 - 1 ))
  (( idxunit < 0 )) && idxunit=0
  (( idxunit > 5 )) && idxunit=5
  local lentrim=$(( ndigits - (idxunit * 3) ))
  printf -v "$var_name" "%s%s" "${val:0:$lentrim}" "${hrunits[$idxunit]}"
}

declare -A prev_rx prev_tx

while snore "${isecs}"; do
  rx_agg_rate=0
  tx_agg_rate=0
  tooltip=""

  # 3. 极速行解析：指定 IFS=' :'，用原生 read -a 拆分 /proc/net/dev
  # 无需正则、无需 Here-String (<<<)、无需外部命令
  while IFS=' :' read -r -a fields; do
    dev="${fields[0]}"
    
    # 自动跳过表头以及非目标网卡
    [[ -n "${is_target_iface[$dev]}" ]] || continue

    rx_b=${fields[1]}
    tx_b=${fields[9]}

    p_rx=${prev_rx[$dev]:-$rx_b}
    p_tx=${prev_tx[$dev]:-$tx_b}

    rx_rate=$(( (rx_b - p_rx) / isecs ))
    tx_rate=$(( (tx_b - p_tx) / isecs ))

    prev_rx[$dev]=$rx_b
    prev_tx[$dev]=$tx_b

    (( rx_agg_rate += rx_rate ))
    (( tx_agg_rate += tx_rate ))

    # 直接传参写入变量，不产生命令替换 $(...)
    human_readable $rx_rate dev_rx_str
    human_readable $tx_rate dev_tx_str
    tooltip+="${dev}:  ↓${dev_rx_str}/s   ↑${dev_tx_str}/s\n"
  done < /proc/net/dev

  tooltip="${tooltip%\\n}"

  percentage=$(( (rx_agg_rate + tx_agg_rate) * 100 / rate_max ))
  (( percentage > 100 )) && percentage=100

  # 格式化汇总数据（无子进程）
  human_readable $rx_agg_rate rx_str
  human_readable $tx_agg_rate tx_str

  printf '{"text": "%4s↓  %4s↑ ", "tooltip": "%s", "percentage": %d}\n' \
    "$rx_str" "$tx_str" "$tooltip" "$percentage"
done
