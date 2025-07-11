#!/bin/sh

get_led_file_for_port() {
    case "$1" in
        "ata1") echo "/sys/class/leds/green:disk/brightness" ;;
        "ata2") echo "/sys/class/leds/green:disk_1/brightness" ;;
        "ata3") echo "/sys/class/leds/green:disk_2/brightness" ;;
        *) echo "" ;;
    esac
}

get_active_ata_ids() {
    ls -l /sys/block 2>/dev/null | grep -i "ata" | \
    awk -F'ata' '{print "ata"$2}' | awk '{print $1}' | \
    cut -d'/' -f1 | grep -o 'ata[0-9]\+' | sort -u || true
}

CONFIGURED_PORTS="ata1 ata2 ata3"

ACTIVE_PORTS_AT_BOOT=$(get_active_ata_ids)

for port in $CONFIGURED_PORTS; do
    initial_state=0
    
    for active_port in $ACTIVE_PORTS_AT_BOOT; do
        if [ "$port" = "$active_port" ]; then
            initial_state=1
            break
        fi
    done
    
    led_file=$(get_led_file_for_port "$port")
    if [ -n "$led_file" ] && [ -f "$led_file" ]; then
        echo "$initial_state" > "$led_file"
    fi

    eval STATE_$port=$initial_state
done

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
            if [ -n "$port" ]; then
                if [ -d "/sys/class/ata_port/$port/device" ]; then
                    new_value=1
                else
                    new_value=0
                fi
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
            fi
        fi
    fi
done
