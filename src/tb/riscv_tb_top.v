`timescale 1 ns / 1 ps

module riscv_tb_top();
//clk & rst control
reg clk;
reg rst_b;
reg riscv_enable;

initial begin
  $display("initial begin...");
  riscv_enable = 1'b0;
  clk = 1'b0;
  rst_b = 1'b1;
  #5;
  rst_b = 1'b0;
  #5;
  rst_b = 1'b1;
  #5;
  riscv_enable = 1'b1;
  $display("initial done...");
end

always begin
  if(riscv_enable)
    #5 clk = ~clk;//100m
  else
    #5;
end

//for debug check
wire [31:0] pc_if = u_soc_riscv_top.u0_myCPU.u_decoder.pc_if;
wire [31:0] pc_dec = u_soc_riscv_top.u0_myCPU.u_decoder.pc_dec;

reg [31:0] pc_exe,pc_mem,pc_wb;
always @(posedge clk or negedge rst_b) begin
  if(~rst_b) begin
    pc_exe <= 32'd0;
    pc_mem <= 32'd0;
    pc_wb  <= 32'd0;
  end
  else begin
    pc_exe <= pc_dec;
    pc_mem <= pc_exe;
    pc_wb  <= pc_mem;
  end
end

//load cmd to mem
initial begin
  wait(riscv_enable) begin
    $display("load cmd to mem");
    $readmemh ("inst.data", u_soc_riscv_top.u0_riscv_rom.u0_mem);
    $display("mem cmd 0: %x", u_soc_riscv_top.u0_riscv_rom.u0_mem[0]);
  end
end

integer r;
`ifdef RISCV_TESTS
//riscv_tests: check cmd result
wire [31:0] x3  = u_soc_riscv_top.u0_myCPU.u_regfile.regfile[2];
wire [31:0] x26 = u_soc_riscv_top.u0_myCPU.u_regfile.regfile[25];
wire [31:0] x27 = u_soc_riscv_top.u0_myCPU.u_regfile.regfile[26];

initial begin
 wait(x26 == 32'b1)  // wait sim end, when x26 == 1
 #100
 if (x27 == 32'b1) begin
     $display("~~~~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~");
     $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
     $display("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~");
     $display("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~");
     $display("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~");
     $display("~~~~~~~~~ #####   ######       #       #~~~~~~~~~");
     $display("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~");
     $display("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~");
     $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
 end//if 
 else begin
     $display("~~~~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~");
     $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
     $display("~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~");
     $display("~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~");
     $display("~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~");
     $display("~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~");
     $display("~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~");
     $display("~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~");
     $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
     $display("fail testnum = %2d", x3);
     for (r = 0; r < 32; r = r + 1)
         $display("x%2d = 0x%x", r, u_soc_riscv_top.u0_myCPU.u_regfile.regfile[r]);
 end//else
 $finish;
end
`endif

`ifdef RISCV_COMPLIANCE
//riscv_compliance: check result
wire[31:0] ex_end_flag = u_soc_riscv_top.u0_riscv_ram.u0_mem[4];
wire[31:0] begin_signature = u_soc_riscv_top.u0_riscv_ram.u0_mem[2];
wire[31:0] end_signature = u_soc_riscv_top.u0_riscv_ram.u0_mem[3];
integer fd;

initial begin
  wait(ex_end_flag == 32'h1);
  
  fd = $fopen("signature.output");
  for (r = begin_signature; r < end_signature; r = r + 4) begin
      $fdisplay(fd, "%x", u_soc_riscv_top.u0_riscv_rom.u0_mem[r[31:2]]);
  end
  $fclose(fd);
  
  #100;
  $finish;
end

`endif


//dump waveform
initial begin
    $dumpfile("riscv_tb_top.vcd");
    $dumpvars(0, riscv_tb_top);
end

//timeout sim
initial begin
     #30000;
     $display("Time Out.");
     $finish;
end


//instance
miniRV_SoC u_soc_riscv_top(
.clk(clk),
.rst_b(rst_b)
);

endmodule
