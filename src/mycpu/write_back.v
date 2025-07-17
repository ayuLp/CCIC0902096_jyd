module write_back(
input clk,
input rst_b,

//clear
input clear_ctl,

//hold
input hold_ctl,

input lb_mem,
input lh_mem,
input lbu_mem,
input lhu_mem,
input lw_mem,
input sb_mem,
input sh_mem,
input sw_mem,
input reg_wen_mem,
input [4:0] reg_waddr_mem,
input [31:0] reg_wdata_mem,

input [31:0] mem_rdata_mem_ctl_mem,
input [31:0] reg_rdata2_mem,

input [31:0] mem_addr_mem,
output reg [31:0] mem_addr_wb_pre,
output reg [31:0] mem_wdata_wb_pre,
output reg        mem_wen_wb_pre,
output reg        mem_cs_en_wb_pre,

output reg [31:0] reg_wdata_wb_pre,
output reg reg_wen_wb,
output reg [4:0] reg_waddr_wb,
output reg [31:0] reg_wdata_wb
);


always @(*) begin
  mem_wdata_wb_pre = 32'd0;
  mem_addr_wb_pre  = 32'd0;
  mem_wen_wb_pre   = 1'b0;
  mem_cs_en_wb_pre = 1'b0;
  reg_wdata_wb_pre = reg_wdata_mem;
  if(lb_mem) begin
    case(mem_addr_mem[1:0])
      2'b00: reg_wdata_wb_pre = {{24{mem_rdata_mem_ctl_mem[7]}},mem_rdata_mem_ctl_mem[7:0]};
      2'b01: reg_wdata_wb_pre = {{24{mem_rdata_mem_ctl_mem[15]}},mem_rdata_mem_ctl_mem[15:8]};
      2'b10: reg_wdata_wb_pre = {{24{mem_rdata_mem_ctl_mem[23]}},mem_rdata_mem_ctl_mem[23:16]};
      2'b11: reg_wdata_wb_pre = {{24{mem_rdata_mem_ctl_mem[31]}},mem_rdata_mem_ctl_mem[31:24]};
    endcase
  end

  if(lh_mem) begin
    case(mem_addr_mem[1:0])
      2'b00: reg_wdata_wb_pre = {{16{mem_rdata_mem_ctl_mem[15]}},mem_rdata_mem_ctl_mem[15:0]};
      2'b10: reg_wdata_wb_pre = {{16{mem_rdata_mem_ctl_mem[31]}},mem_rdata_mem_ctl_mem[31:16]};
    endcase
  end

  if(lbu_mem) begin
    case(mem_addr_mem[1:0])
      2'b00: reg_wdata_wb_pre = {{24{1'b0}},mem_rdata_mem_ctl_mem[7:0]};
      2'b01: reg_wdata_wb_pre = {{24{1'b0}},mem_rdata_mem_ctl_mem[15:8]};
      2'b10: reg_wdata_wb_pre = {{24{1'b0}},mem_rdata_mem_ctl_mem[23:16]};
      2'b11: reg_wdata_wb_pre = {{24{1'b0}},mem_rdata_mem_ctl_mem[31:24]};
    endcase
  end

  if(lhu_mem) begin
    case(mem_addr_mem[1:0])
      2'b00: reg_wdata_wb_pre = {{16{1'b0}},mem_rdata_mem_ctl_mem[15:0]};
      2'b10: reg_wdata_wb_pre = {{16{1'b0}},mem_rdata_mem_ctl_mem[31:16]};
    endcase
  end

  if(lw_mem) reg_wdata_wb_pre = mem_rdata_mem_ctl_mem;
 
  if(sb_mem) begin
    mem_addr_wb_pre  = mem_addr_mem;
    mem_wen_wb_pre   = 1'b1;
    mem_cs_en_wb_pre = 1'b1;
    case(mem_addr_mem[1:0])
      2'b00: mem_wdata_wb_pre = {mem_rdata_mem_ctl_mem[31:8],reg_rdata2_mem[7:0]}; 
      2'b01: mem_wdata_wb_pre = {mem_rdata_mem_ctl_mem[31:16],reg_rdata2_mem[7:0],mem_rdata_mem_ctl_mem[7:0]};
      2'b10: mem_wdata_wb_pre = {mem_rdata_mem_ctl_mem[31:24],reg_rdata2_mem[7:0],mem_rdata_mem_ctl_mem[15:0]};
      2'b11: mem_wdata_wb_pre = {reg_rdata2_mem[7:0],mem_rdata_mem_ctl_mem[23:0]};
    endcase
  end

  if(sh_mem) begin
    mem_addr_wb_pre  = mem_addr_mem;
    mem_wen_wb_pre   = 1'b1;
    mem_cs_en_wb_pre = 1'b1;
    case(mem_addr_mem[1:0])
      2'b00: mem_wdata_wb_pre = {mem_rdata_mem_ctl_mem[31:16],reg_rdata2_mem[15:0]}; 
      2'b10: mem_wdata_wb_pre = {reg_rdata2_mem[15:0],mem_rdata_mem_ctl_mem[15:0]};
    endcase
  end

  if(sw_mem) begin
    mem_wdata_wb_pre = reg_rdata2_mem;
    mem_addr_wb_pre  = mem_addr_mem;
    mem_wen_wb_pre   = 1'b1;
    mem_cs_en_wb_pre = 1'b1;
  end

end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b) begin
    reg_wen_wb       <= 1'b0;
    reg_waddr_wb       <= 5'b0;
    reg_wdata_wb       <= 32'b0;
  end
  else if(hold_ctl) begin
    reg_wen_wb       <= reg_wen_wb;
    reg_waddr_wb       <= reg_waddr_wb;
    reg_wdata_wb       <= reg_wdata_wb;
  end
  else if(clear_ctl) begin
    reg_wen_wb       <= 1'b0;
    reg_waddr_wb       <= 5'b0;
    reg_wdata_wb       <= 32'b0;
  end
  else begin
    reg_wen_wb       <= reg_wen_mem;
    reg_waddr_wb       <= reg_waddr_mem;
    reg_wdata_wb       <= reg_wdata_wb_pre;
  end
end

endmodule
