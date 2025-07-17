module fetch(
    //clk & rst
    input clk,
    input rst_b,

    //jump跳转
    input [31:0] jump_addr_ctl,//跳转地址
    input jump_ctl,//跳转控制

    //control
    input hold_ctl,//暂停控制
    input clear_ctl,//清除控制

    //io with inst mem
    input [31:0] inst_if_ctl,//指令存储器输出
    output reg [31:0] pc_if_pre,//前一个周期的pc取值地址
    output wire pc_req_if_pre,//前一个周期指令存储器请求信号

    //io with decoder
    output reg [31:0] pc_if,//当前指令地址
    output  [31:0] inst_if //当前指令
);

assign pc_req_if_pre = 1'b1;

always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    pc_if_pre <= 32'd0;
  else if(jump_ctl)
    pc_if_pre <= jump_addr_ctl;
  else if(hold_ctl)
    pc_if_pre <= pc_if_pre;
  else if(clear_ctl)
    pc_if_pre <= 32'd0;
  else
    pc_if_pre <= pc_if_pre + 32'd4;
end

always @(posedge clk or negedge rst_b) begin
  if(~rst_b) begin
    pc_if   <= 32'd0;
  end
  else if(hold_ctl) begin
    pc_if   <= pc_if;
  end
  else if(clear_ctl) begin
    pc_if   <= 32'd0;
  end
  else begin
    pc_if   <= pc_if_pre;
  end
end

reg clear_ctl_d,hold_ctl_d;//延迟一个周期后的clear_ctl和hold_ctl，就是上一周期的值
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

wire hold_ctl_on_str = hold_ctl & ~hold_ctl_d;// 捕捉hold_ctl上升沿
reg [31:0] inst_if_ctl_hold;//暂停时的指令
always @(posedge clk or negedge rst_b) begin
  if(~rst_b)
    inst_if_ctl_hold <= 32'd0;
  else if(hold_ctl_on_str)
    inst_if_ctl_hold <= inst_if_ctl;// 在hold_ctl上升沿保存当前指令
end


assign inst_if = hold_ctl_d ? inst_if_ctl_hold : (clear_ctl_d ? 32'd0 : inst_if_ctl);

endmodule
