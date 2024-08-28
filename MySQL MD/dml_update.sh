#!/bin/bash

# 功能：该脚本用于从指定文件中提取以特定字符串开头的行，并将其中的字段名替换为指定的字段名。
# 使用方法：
#   ./script.sh <file_path> <database_name> <table_name> [field_number:field_name...]
# 参数说明：
#   <file_path>      - 要处理的文件路径
#   <database_name>  - 数据库名称
#   <table_name>     - 表名称
#   [field_number:field_name...] - 字段编号和字段名的对应关系，格式为 field_number:field_name

# 示例：
#   ./script.sh data.txt my_database my_table 1:id 2:name 3:age

# 检查参数数量
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <file_path> <database_name> <table_name> [field_number:field_name...]"
    exit 1
fi

# 获取参数
file_path="$1"
database_name="$2"
table_name="$3"
shift 3
field_pairs=("$@")

# 检查文件是否存在
if [ ! -f "$file_path" ]; then
    echo "File not found: $file_path"
    exit 1
fi

# 使用awk提取以指定字符串开头的行，并替换WHERE为SET，然后提取指定字段
awk -v db="$database_name" -v tbl="$table_name" -v fields="${field_pairs[*]}" -F'@' '
    BEGIN { 
        pattern = "^UPDATE `" db "`.`" tbl "`"
        split(fields, field_arr, " ")
    }
    $0 ~ pattern {
        gsub(/WHERE/, "SET")
        output = $1
        for (i in field_arr) {
            split(field_arr[i], pair, ":")
            field_num = pair[1]
            field_name = pair[2]
            count = 0
            for (j = 2; j <= NF; j++) {
                if ($j ~ ("^" field_num "=")) {
                    count++
                    if (count == 2) {
                        output = output " " $j
                        break
                    }
                }
            }
        }
        output = output " WHERE " $2
        print output
    }
' "$file_path" | awk -v fields="${field_pairs[*]}" '
    BEGIN { split(fields, field_arr, " ") }
    {
        for (i in field_arr) {
            split(field_arr[i], pair, ":")
            field_num = pair[1]
            field_name = pair[2]
            gsub(" " field_num "=", " `" field_name "`=")
        }
        gsub(" 1=", " `id`=")
        $0 = gensub(/ +$/, "", "g", $0)  # 去除行尾的空格
        $0 = gensub(/ +/, " ", "g", $0)  # 合并多个连续的空格
        print $0 ";"
    }
'

