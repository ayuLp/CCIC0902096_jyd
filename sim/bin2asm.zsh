#! /bin/zsh

input_file=$1
in_wo_path="${input_file##*/}"
output_file="${in_wo_path%.*}.asm"

riscv64-unknown-elf-objdump -b binary -m riscv:rv32 -M no-aliases -D $input_file > $output_file
