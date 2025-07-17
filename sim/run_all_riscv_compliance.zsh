#! /bin/zsh

#bin_path="riscv_compliance/*/isa_bin/"
bin_list_str=`ls riscv_compliance/*/isa_bin/*.bin | tr -s "\r\n" " "`
read -r -A bin_list <<< $bin_list_str

fail_flag=0

foreach bin_name ($bin_list)
  echo "bin name: $bin_name"
  #clear env
  rm *.asm
  rm *.hex
  rm run.log
  #build env
  ./BinToMem_CLI.py $bin_name
  ./bin2asm.zsh $bin_name
  
  #run
  ./run.zsh RISCV_COMPLIANCE | tee run.log

  #result check
  grep -q "TEST_PASS" run.log
  if [ $? -ne 0 ]
  then
    echo "$bin_name test fail!!!"
    fail_flag=1
    break
  fi
end

if [ $fail_flag -eq 1 ]
then
  echo "run all fail!!!"
else
  echo "run_all pass"
fi
