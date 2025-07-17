#! /bin/zsh

#clear
./run_clear.zsh

ln -s *.hex inst.data
ln -s *.asm inst.asm

case_type="RISCV_TESTS"

if [ $# -gt 0 ]; then
  case_type=$1
else
  echo "avaliable mode: RISCV_TESTS | RISCV_COMPLIANCE"
fi

echo "current mode: $case_type"

#compile
iverilog -o out.vvp -f filelist.f -v -Wall -D $case_type

#sim
vvp -n out.vvp -v

#compare reslut
if [[ -f "signature.output" ]]; then
  ref_path="riscv_compliance"
  ref_name_hex=`ls *.hex`
  ref_name_tmp="${ref_name_hex%.*}"
  ref_name="${ref_name_tmp%.*}.reference_output"
  ref_name_wipath=`ls $ref_path/*/*/$ref_name`
  ln -s $ref_name_wipath .
  
  diff signature.output $ref_name_wipath
  
  if [ $? -ne 0 ]; then
    echo "~~~~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~" 
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~"
    echo "~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~"
    echo "~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~"
    echo "~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~"
    echo "~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~"
    echo "~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~"
    echo "~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~"
    echo "~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~"
    echo "~~~~~~~~~ #####   ######       #       #~~~~~~~~~"
    echo "~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~"
    echo "~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  fi
fi
