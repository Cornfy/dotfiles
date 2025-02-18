#!/bin/bash

# network_traffic.sh [-tPOLLING_INTERVAL] [NETWORK_INTERFACE...]

getopts t: __ && shift
isecs=${OPTARG:-1}
ifaces=($@)
: ${rate_max:=1000000}

snore() {
    local IFS
    [[ -n "${_snore_fd:-}" ]] || { exec {_snore_fd}<> <(:); } 2>/dev/null
    read ${1:+-t "$1"} -u $_snore_fd || :
}

human_readable() {
  local hrunits=( B K M G T P )
  local ndigits=${#1}
  local idxunit=$(( (2 + ndigits) / 3 - 1))
  local lentrim=$(( ndigits - (idxunit * 3 ) ))
  echo ${1::$lentrim}${hrunits[$idxunit]}
}

exit_err() {
  printf '{"text": "⚠ %s", "tooltip": "%s", "class": "error"}\n' "$@"
  exit
}

if test ${#ifaces[@]} -gt 0; then
  for iface in ${ifaces[@]}; do
    test -h "/sys/class/net/${iface}" || exit_err "${iface}" "${iface} is not an existing network interface name"
  done
else
  ifaces=(/sys/class/net/*)
  ifaces=(${ifaces[@]##*/})
  ifaces=(${ifaces[@]//lo/})
fi

if test ${isecs} -lt 1; then
  exit_err "${isecs}" "${isecs} is not a valid polling interval"
fi

for iface in ${ifaces[@]} aggregate; do
  declare -a traffic_prev_${iface} traffic_curr_${iface} traffic_delt_${iface}
  declare -n traffic_prev=traffic_prev_${iface}
  declare -n traffic_curr=traffic_curr_${iface}
  declare -n traffic_delt=traffic_delt_${iface}
  traffic_prev=( 0 0 0 0  0 0 0 0 )
  traffic_curr=( 0 0 0 0  0 0 0 0 )
  traffic_delt=( 0 0 0 0  0 0 0 0 )
done

while snore ${isecs} ;do
  tooltip=""
  traffic_delt_aggregate=( 0 0 0 0  0 0 0 0 )

  readarray -s2 proc_net_dev </proc/net/dev
  while read -a data; do
    iface=${data[0]%:}
    test "${ifaces[*]}" = "${ifaces[*]//${iface}/}" && continue
    declare -n traffic_prev=traffic_prev_${iface}
    declare -n traffic_curr=traffic_curr_${iface}
    declare -n traffic_delt=traffic_delt_${iface}
    traffic_curr=(${data[@]:1:4} ${data[@]:9:4})
    for i in {0..7}; do
      (( traffic_delt[i] = ( traffic_curr[i] - traffic_prev[i] ) / isecs ))
      (( traffic_delt_aggregate[i] += traffic_delt[i] ))
    done
    traffic_prev=(${traffic_curr[@]})
  done <<<"${proc_net_dev[@]}"

  printf '{"text": "%4s↓  %4s↑ ", "tooltip": "%s",  "percentage": %d}\n'   \
    $(human_readable ${traffic_delt_aggregate[0]})  \
    $(human_readable ${traffic_delt_aggregate[4]})  \
    "${tooltip}"                                    \
    $(( ( traffic_delt_aggregate[0] + traffic_delt_aggregate[4] ) / rate_max ))
done
