#!/bin/bash

# 该脚本用于从指定文件中提取以 DELETE FROM `<数据库名>`.`<表名>` 开头的行，
# 并将这些行中的 DELETE FROM 替换为 INSERT INTO，将 WHERE 替换为 VALUES，
# 将 @1= 替换为 (，将 @任意位数字= 替换为 , ，并在行尾加上 );。
# 输入文件路径是 /data/tmp/dml.sql，数据库名和表名以参数的形式传入。

# 用法: ./modify_lines.sh <数据库名> <表名>

# 检查是否提供了足够的参数
if [ "$#" -ne 2 ]; then
    echo "用法: $0 <数据库名> <表名>"
    exit 1
fi

# 获取参数
database_name=$1
table_name=$2

# 定义输入文件路径
input_file="/data/tmp/dml.sql"

# 检查输入文件是否存在
if [ ! -f "$input_file" ]; then
    echo "错误: 输入文件 $input_file 不存在。"
    exit 1
fi

# 使用 awk 提取以指定模式开头的行，并进行替换，然后输出到终端
awk -v db="$database_name" -v tbl="$table_name" '
    $0 ~ "^DELETE FROM `" db "`.`" tbl "`" {
        gsub(/^DELETE FROM/, "INSERT INTO");
        gsub(/WHERE/, "VALUES");
        gsub(/@1=/, "(");
        gsub(/[[:space:]]+@([0-9]+)=/, ", ");
        gsub(/[[:space:]]+/, " ");  # 将多个空格合并成一个空格
        print $0 ");"
    }
' "$input_file"

