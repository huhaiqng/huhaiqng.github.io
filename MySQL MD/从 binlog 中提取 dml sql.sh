#!/bin/bash

# 脚本功能说明：
# 这个脚本用于处理 MySQL binlog 文件，生成包含特定 DML 语句的 SQL 文件。
# 它会检查系统中是否安装了 mysqlbinlog 命令，并检查传入的 binlog 文件是否存在。
# 然后，它会生成一个中间文件 binlog.sql，并使用 awk 处理这个文件，
# 将符合条件的行输出到 dml.sql 文件中。

# 检查是否提供了至少一个 binlog 文件
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 binlog_file1 [binlog_file2 ...]"
    exit 1
fi

# 检查是否安装了 mysqlbinlog 命令
if ! command -v mysqlbinlog &> /dev/null; then
    echo "mysqlbinlog command not found. Please install MySQL client tools."
    exit 1
fi

# 检查每个 binlog 文件是否存在
for binlog_file in "$@"; do
    if [ ! -f "$binlog_file" ]; then
        echo "Binlog file $binlog_file not found."
        exit 1
    fi
done

# 定义输入文件和输出文件路径
input_file="/data/tmp/binlog.sql"
output_file="/data/tmp/dml.sql"

# 清空或创建输入文件
> "$input_file"

# 处理每个 binlog 文件，生成 binlog.sql 文件
for binlog_file in "$@"; do
    mysqlbinlog --base64-output=DECODE-ROWS -v "$binlog_file" >> "$input_file"
done

# 使用 awk 处理 binlog.sql 文件，生成 dml.sql 文件
awk '
{
    if (match($0, /^### (INSERT|DELETE|UPDATE)/)) {
        if (NR > 1 && match(prev, /^#+[0-9]{6}/)) {
            # 提取前两个字段
            split(prev, fields, " ")
            print fields[1], fields[2] >> "'$output_file'"
        }
        combined_line = $0
        gsub(/### /, "", combined_line)  # 去除行中的 "### "
        next_line = 1
    } else if (next_line && match($0, /^###/)) {
        sub(/^### /, "", $0)  # 去除行首的 "### "
        combined_line = combined_line " " $0
        gsub(/### /, "", combined_line)  # 去除行中的 "### "
    } else if (next_line) {
        print combined_line >> "'$output_file'"
        next_line = 0
    }
    prev = $0
}
END {
    if (next_line) {
        print combined_line >> "'$output_file'"
    }
}
' "$input_file"

