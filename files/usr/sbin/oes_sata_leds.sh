#!/bin/sh

get_led_file_for_port() {
    case "$1" in
        "ata1") echo "/sys/class/leds/green:disk/brightness" ;;
        "ata2") echo "/sys/class/leds/green:disk_1/brightness" ;;
        "ata3") echo "/sys/class/leds/green:disk_2/brightness" ;;
        *) echo "" ;;
    esac
}

CONFIGURED_PORTS="ata1 ata2 ata3"

get_initial_state_from_log() {
    local port="$1"
    local last_event
    local initial_state=0

    last_event=$(logread | grep -E "${port}:|${port}\.00:" | tail -n 1)

    if [ -n "$last_event" ]; then
        case "$last_event" in
            *": SATA link up"* | *".00: configured"*)
                initial_state=1
                ;;
            *": SATA link down"* | *": device_remove"*)
                initial_state=0
                ;;
            *": EH complete"*)
                 initial_state=1
                 ;;
            *)
                initial_state=0
                ;;
        esac
        echo "$(date '+%Y-%m-%d %T') - 初始检查: $port 的最后事件为: \"$last_event\" -> 状态: $initial_state"
    else
        echo "$(date '+%Y-%m-%d %T') - 初始检查: $port 在历史日志中未找到事件，默认状态为 0"
    fi

    echo "$initial_state"
}

echo "$(date '+%Y-%m-%d %T') - 脚本启动，开始通过分析历史日志检查设备状态..."

for port in $CONFIGURED_PORTS; do
    initial_state=$(get_initial_state_from_log "$port")
    
    led_file=$(get_led_file_for_port "$port")
    if [ -n "$led_file" ] && [ -f "$led_file" ]; then
        echo "$initial_state" > "$led_file"
        echo "$(date '+%Y-%m-%d %T') - 初始化: $led_file 设置为 $initial_state"
    else
        echo "$(date '+%Y-%m-%d %T') - 错误: $port 的LED文件 '$led_file' 不存在。" >&2
    fi

    eval STATE_$port=$initial_state
done

echo "$(date '+%Y-%m-%d %T') - 初始化完成，开始监控实时日志..."

logread -f | while read -r line; do
    port=""
    new_value=""

    case "$line" in
        *": SATA link up"* | *".00: configured"*)
            port=$(echo "$line" | sed -n 's/.*\(ata[0-9]\+\).*/\1/p')
            new_value=1
            ;;
        *": SATA link down"* | *": device_remove"*)
            port=$(echo "$line" | sed -n 's/.*\(ata[0-9]\+\).*/\1/p')
            new_value=0
            ;;
        *": EH complete"*)
            port=$(echo "$line" | sed -n 's/.*\(ata[0-9]\+\).*/\1/p')
            if [ -n "$port" ] && [ -d "/sys/class/ata_port/$port/device" ]; then
                new_value=1
            else
                new_value=0
            fi
            ;;
    esac

    if [ -n "$port" ] && [ -n "$new_value" ]; then
        led_file=$(get_led_file_for_port "$port")
        if [ -n "$led_file" ] && [ -f "$led_file" ]; then
            current_state=$(eval echo \$STATE_$port)
            if [ "$current_state" != "$new_value" ]; then
                echo "$new_value" > "$led_file"
                eval STATE_$port=$new_value
                echo "$(date '+%Y-%m-%d %T') - 端口 $port 状态变更为 $new_value. (事件: ${line})"
            fi
        fi
    fi
done
