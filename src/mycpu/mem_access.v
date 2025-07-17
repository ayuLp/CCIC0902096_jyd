module mem_access (
input clk,
input rst_b,

//clear ctl
input clear_ctl,

//input hold
input hold_ctl,

input reg_wen_exe,
input [4:0] reg_waddr_exe,
input [31:0] reg_wdata_exe,
input [31:0] reg_rdata2_exe,

input [31:0] mem_addr_exe,

input lb_exe,
input lh_exe,
input lbu_exe,
input lhu_exe,
input lw_exe,
input sb_exe,
input sh_exe,
input sw_exe,

output reg [31:0] reg_rdata2_mem,

output reg lb_mem,
output reg lh_mem,
output reg lbu_mem,
output reg lhu_mem,
output reg lw_mem,
output reg sb_mem,
output reg sh_mem,
output reg sw_mem,

output reg reg_wen_mem,
output reg [4:0] reg_waddr_mem,
output reg [31:0] reg_wdata_mem,

output reg mem_cs_en_mem_pre,
output reg mem_wen_mem_pre,
output reg [31:0] mem_addr_mem_pre,
input  [31:0] mem_rdata_mem_ctl,
output  [31:0] mem_rdata_mem_ctl_mem,

output reg [31:0] mem_addr_mem
);


always @(*) begin
  mem_cs_en_mem_pre = 1'b0;
  mem_wen_mem_pre   = 1'b0;
  mem_addr_mem_pre  = 32'd0;
  
  if(lb_exe | lh_exe | lbu_exe | lhu_exe | lw_exe | sb_exe | sh_exe | sw_exe) begin
    mem_cs_en_mem_pre = 1'b1;
    mem_wen_mem_pre   = 1'b0;
    mem_addr_mem_pre  = mem_addr_exe;
  end

end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b) begin
    lb_mem            <= 1'b0;
    lh_mem            <= 1'b0;
    lbu_mem           <= 1'b0;
    lhu_mem           <= 1'b0;
    lw_mem            <= 1'b0;
    sb_mem            <= 1'b0;
    sh_mem            <= 1'b0;
    sw_mem            <= 1'b0;
    reg_wen_mem         <= 1'b0;
    reg_waddr_mem         <= 5'b0;
    reg_wdata_mem         <= 32'b0;
    mem_addr_mem          <= 32'd0;
    reg_rdata2_mem        <= 32'd0;
  end
  else if(hold_ctl) begin
    lb_mem            <= lb_mem           ;
    lh_mem            <= lh_mem           ;
    lbu_mem           <= lbu_mem          ;
    lhu_mem           <= lhu_mem          ;
    lw_mem            <= lw_mem           ;
    sb_mem            <= sb_mem;
    sh_mem            <= sh_mem;
    sw_mem            <= sw_mem;
    reg_wen_mem         <= reg_wen_mem        ;
    reg_waddr_mem         <= reg_waddr_mem        ;
    reg_wdata_mem         <= reg_wdata_mem        ;
    mem_addr_mem          <= mem_addr_mem;
    reg_rdata2_mem        <= reg_rdata2_mem;
  end
  else if(clear_ctl) begin
    lb_mem            <= 1'b0;
    lh_mem            <= 1'b0;
    lbu_mem           <= 1'b0;
    lhu_mem           <= 1'b0;
    lw_mem            <= 1'b0;
    sb_mem            <= 1'b0;
    sh_mem            <= 1'b0;
    sw_mem            <= 1'b0;
    reg_wen_mem         <= 1'b0;
    reg_waddr_mem         <= 5'b0;
    reg_wdata_mem         <= 32'b0;
    mem_addr_mem          <= 32'd0;
    reg_rdata2_mem        <= 32'd0;
  end
  else begin
    lb_mem            <= lb_exe        ;
    lh_mem            <= lh_exe        ;
    lbu_mem           <= lbu_exe       ;
    lhu_mem           <= lhu_exe       ;
    lw_mem            <= lw_exe        ;
    sb_mem            <= sb_exe;
    sh_mem            <= sh_exe;
    sw_mem            <= sw_exe;
    reg_wen_mem         <= reg_wen_exe     ;
    reg_waddr_mem         <= reg_waddr_exe     ;
    reg_wdata_mem         <= reg_wdata_exe     ;
    mem_addr_mem          <= mem_addr_exe;
    reg_rdata2_mem        <= reg_rdata2_exe;
  end
end

reg clear_ctl_d,hold_ctl_d;
always @(posedge clk or negedge rst_b) begin
  if(~rst_b) begin
    clear_ctl_d <= 1'b0;
    hold_ctl_d  <= 1'b0;
  end
  else begin
    clear_ctl_d <= clear_ctl;
    hold_ctl_d  <= hold_ctl;
  end
end

wire hold_ctl_on_str = hold_ctl & ~hold_ctl_d;
reg [31:0] mem_rdata_mem_ctl_hold;
always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    mem_rdata_mem_ctl_hold <= 32'd0;
  else if(hold_ctl_on_str)
    mem_rdata_mem_ctl_hold <= mem_rdata_mem_ctl;
end


assign mem_rdata_mem_ctl_mem = hold_ctl_d ? mem_rdata_mem_ctl_hold : (clear_ctl_d ? 32'd0 : mem_rdata_mem_ctl);

endmodule
