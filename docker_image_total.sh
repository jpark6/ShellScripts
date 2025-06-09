#!/bin/bash

docker images --format "{{.Size}}" | awk '
/GB/ {g += $1}
/MB/ {m += $1}
/kB/ {k += $1}
END {
    total = g * 1024 + m + k / 1024
    printf "총 이미지 용량: %.2f MB\n", total
}'

