#!/usr/bin/env bash

# This script shows the rough encoding progress of the currently most CPU
# intensive ffmpeg.

# Find most CPU-intensive ffmpeg
pid=$(ps -eo pid,pcpu,comm --sort=-pcpu | awk '$3=="ffmpeg"{print $1; exit}')
if [ -z "$pid" ]; then
    echo "no job"
    exit 0
fi

# Get full command line and extract first input after -i
cmd=$(ps -p "$pid" -o args=)
input=$(printf "%s\n" "$cmd" | sed -n 's/.*-i[[:space:]]\+\([^[:space:]]\+\).*/\1/p')
if [ -z "$input" ]; then
    echo "could not parse input"
    exit 1
fi
if [ ! -f "$input" ]; then
    echo "input not a file: $input"
    exit 1
fi

# Find fd pointing to that file
fd=$(ls -l /proc/"$pid"/fd 2>/dev/null | awk -v f="$input" '$NF==f{print $9}')
if [ -z "$fd" ]; then
    echo "fd not found"
    exit 1
fi

# read current offset
pos=$(awk '/^pos:/ {print $2}' /proc/"$pid"/fdinfo/"$fd")
size=$(stat -c %s "$input")
pct=$(awk -v p="$pos" -v s="$size" 'BEGIN{printf "%.2f", (p/s)*100}')

echo "$pct%   $input"
