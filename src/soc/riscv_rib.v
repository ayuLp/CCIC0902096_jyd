module riscv_rib #(
parameter mst_num = 3,
parameter slv_num = 3
)(
input clk,
input rst_b,

input      [mst_num*32-1:0] rib_addr_mst,
input      [mst_num*32-1:0] rib_wdata_mst,
output reg [mst_num*32-1:0] rib_rdata_mst,
input      [mst_num-1   :0] rib_req_mst,
input      [mst_num-1   :0] rib_wr_en_mst,

output reg [slv_num*32-1:0] rib_addr_slv,
output reg [slv_num*32-1:0] rib_wdata_slv,
input      [slv_num*32-1:0] rib_rdata_slv,
output reg [slv_num-1   :0] rib_req_slv,
output reg [slv_num-1   :0] rib_wr_en_slv,

output reg  rib_core_hold
);


always @(*) begin
  rib_addr_slv  = {slv_num*32{1'b0}};
  rib_wdata_slv = {slv_num*32{1'b0}};
  rib_req_slv   = {slv_num{1'b0}};
  rib_wr_en_slv = {slv_num{1'b0}};
  rib_core_hold = 1'b0;

  if(rib_req_mst[0]) begin//mst_first
    case(rib_addr_mst[31:28])
      4'b0000:
        begin
          rib_addr_slv[31:0]    = rib_addr_mst[31:0];
          rib_wdata_slv[31:0]   = rib_wdata_mst[31:0];
          rib_req_slv[0]        = rib_req_mst[0];
          rib_wr_en_slv[0]      = rib_wr_en_mst[0];
          rib_core_hold         = 1'b1;
        end
      4'b0001:
        begin
          rib_addr_slv[32+31:32+0]    = rib_addr_mst[31:0];
          rib_wdata_slv[32+31:32+0]   = rib_wdata_mst[31:0];
          rib_req_slv[1]              = rib_req_mst[0];
          rib_wr_en_slv[1]            = rib_wr_en_mst[0];
          rib_core_hold               = 1'b1;
        end
    endcase
  end//if
  else if(rib_req_mst[1]) begin
    case(rib_addr_mst[32+31:32+28])
      4'b0000:
        begin
          rib_addr_slv[31:0]          = rib_addr_mst[32+31:32+0];
          rib_wdata_slv[31:0]         = rib_wdata_mst[32+31:32+0];
          rib_req_slv[0]              = rib_req_mst[1];
          rib_wr_en_slv[0]            = rib_wr_en_mst[1];
          rib_core_hold               = 1'b1;
        end
      4'b0001:
        begin
          rib_addr_slv[32+31:32+0]    = rib_addr_mst[32+31:32+0];
          rib_wdata_slv[32+31:32+0]   = rib_wdata_mst[32+31:32+0];
          rib_req_slv[1]              = rib_req_mst[1];
          rib_wr_en_slv[1]            = rib_wr_en_mst[1];
          rib_core_hold               = 1'b1;
        end
    endcase      
  end//if
  else if(rib_req_mst[2]) begin//mst_last
    case(rib_addr_mst[2*32+31:2*32+28])
      4'b0000:
        begin
          rib_addr_slv[31:0]              = rib_addr_mst[32*2+31:32*2+0];
          rib_wdata_slv[31:0]             = rib_wdata_mst[32*2+31:32*2+0];
          rib_req_slv[0]                  = rib_req_mst[2];
          rib_wr_en_slv[0]                = rib_wr_en_mst[2];
          rib_core_hold                   = 1'b0;
        end
      4'b0001:
        begin
          rib_addr_slv[32+31:32+0]        = rib_addr_mst[32*2+31:32*2+0];
          rib_wdata_slv[32+31:32+0]       = rib_wdata_mst[32*2+31:32*2+0];
          rib_req_slv[1]                  = rib_req_mst[2];
          rib_wr_en_slv[1]                = rib_wr_en_mst[2];
          rib_core_hold                   = 1'b0;
        end
    endcase      
  end//if
end


reg [mst_num-1:0] rib_req_mst_d;
reg [mst_num*32-1:0] rib_addr_mst_d;
always @(posedge clk or negedge rst_b) begin
  if(~rst_b) begin
    rib_req_mst_d <= {mst_num{1'b0}};
    rib_addr_mst_d <= {mst_num*32{1'b0}};
  end
  else begin
    rib_req_mst_d <= rib_req_mst;
    rib_addr_mst_d <= rib_addr_mst;
  end
end

always @(*) begin
  rib_rdata_mst = {mst_num*32{1'b0}};

  if(rib_req_mst_d[0]) begin//mst_first
    case(rib_addr_mst_d[31:28])
      4'b0000:
        begin
          rib_rdata_mst[31:0]   = rib_rdata_slv[31:0];
        end
      4'b0001:
        begin
          rib_rdata_mst[31:0]         = rib_rdata_slv[32+31:32+0];
        end
    endcase
  end//if
  else if(rib_req_mst_d[1]) begin
    case(rib_addr_mst_d[32+31:32+28])
      4'b0000:
        begin
          rib_rdata_mst[32+31:32+0]   = rib_rdata_slv[31:0];
        end
      4'b0001:
        begin
          rib_rdata_mst[32+31:32+0]   = rib_rdata_slv[32+31:32+0];
        end
    endcase      
  end//if
  else if(rib_req_mst_d[2]) begin//mst_last
    case(rib_addr_mst_d[2*32+31:2*32+28])
      4'b0000:
        begin
          rib_rdata_mst[32*2+31:32*2+0]   = rib_rdata_slv[31:0];
        end
      4'b0001:
        begin
          rib_rdata_mst[32*2+31:32*2+0]   = rib_rdata_slv[32+31:32+0];
        end
    endcase      
  end//if
end

endmodule
