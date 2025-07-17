module myCPU(
  input clk,
  input rst_b,

  input  [31:0] mem_rdata_top,
  output [31:0] mem_addr_ctl,
  output [31:0] mem_wdata_ctl,
  output        mem_wen_ctl,
  output        mem_cs_en_ctl,

  //ext hold
  input       ext_hold_top,
  //ext irq
  input [7:0] ext_ini_flag_top
);

//wire define
wire        jump_if_ctl;
wire [31:0] jump_addr_if_ctl;

wire hold_if_ctl;
wire hold_dec_ctl;
wire hold_exe_ctl;
wire hold_mem_ctl;
wire hold_wb_ctl;

wire clear_if_ctl;
wire clear_dec_ctl;
wire clear_exe_ctl;
wire clear_mem_ctl;
wire clear_wb_ctl;

wire [31:0] inst_if;
wire [31:0] pc_if_pre;
wire [31:0] inst_if_ctl;
wire        pc_req_if_pre;
wire [31:0] pc_if;       

wire [31:0] pc_dec;
wire [31:0] imm_dec;
wire        imm_en_dec;  
wire sll_dec;  
wire srl_dec;  
wire sra_dec;  
wire add_dec;  
wire sub_dec;  
wire lui_dec;  
wire auipc_dec;  
wire xor_dec;  
wire and_dec;  
wire or_dec;  
wire slt_dec;  
wire sltu_dec;  
wire lb_dec;  
wire lh_dec;  
wire lbu_dec;  
wire lhu_dec;  
wire lw_dec;  
wire sb_dec;  
wire sh_dec;  
wire sw_dec;  
wire ebreak_dec;  
wire ecall_dec;  
wire mret_dec;  
wire jal_dec;  
wire jalr_dec;  
wire beq_dec;  
wire bne_dec;  
wire blt_dec;  
wire bge_dec;  
wire bltu_dec;  
wire bgeu_dec;  
wire fence_dec;
wire fence_i_dec;
wire csrrw_dec;
wire csrrs_dec;
wire csrrc_dec;
wire [4:0] reg_raddr1_dec;  
wire [4:0] reg_raddr2_dec;  
wire [4:0] reg_waddr_dec;  
wire reg_ren1_dec;  
wire reg_ren2_dec;
wire [31:0] reg_rdata1_reg;
wire [31:0] reg_rdata2_reg;
wire [31:0] reg_rdata1_ctl;
wire [31:0] reg_rdata2_ctl;

wire jump_en_exe;
wire [31:0] jump_addr_exe;
wire reg_wen_exe;
wire [4:0] reg_waddr_exe;
wire [31:0] reg_wdata_exe;
wire [31:0] reg_wdata_wb_pre;
wire [31:0] mem_addr_exe;
wire [31:0] reg_rdata2_exe;

wire csr_wen_exe;
wire [11:0] csr_waddr_exe;
wire [31:0] csr_wdata_exe;
wire csr_ren_exe;
wire [11:0] csr_raddr_exe;
wire [31:0] csr_rdata_csr;
wire lb_exe;
wire lh_exe;
wire lbu_exe;
wire lhu_exe;
wire lw_exe;
wire sb_exe;
wire sh_exe;
wire sw_exe;

wire lb_mem;
wire lh_mem;
wire lbu_mem;
wire lhu_mem;
wire lw_mem;
wire sb_mem;
wire sh_mem;
wire sw_mem;

wire [31:0] reg_rdata2_mem;
wire [31:0] mem_rdata_mem_ctl;
wire [31:0] mem_rdata_mem_ctl_mem;
wire [31:0] mem_addr_mem_pre;
wire        mem_cs_en_mem_pre;
wire        mem_wen_mem_pre;
wire [31:0]       mem_addr_mem;

wire reg_wen_mem;
wire [4:0] reg_waddr_mem;
wire [31:0] reg_wdata_mem;

wire reg_wen_wb;
wire [4:0] reg_waddr_wb;
wire [31:0] reg_wdata_wb;

wire [31:0] mem_addr_wb_pre;
wire [31:0] mem_wdata_wb_pre;
wire        mem_wen_wb_pre;
wire        mem_cs_en_wb_pre;

wire [31:0] mstatus_csr;
wire [31:0] mie_csr;
wire [31:0] mtvec_csr;
wire [31:0] mepc_csr;

wire        csr_wen_intp;
wire [11:0] csr_waddr_intp;
wire [31:0] csr_wdata_intp;
wire        ini_clear_intp;
wire        ini_jump_intp;
wire [31:0] ini_jump_addr_intp;

wire        illegal_inst_dec;
wire        load_addr_mis_exe_pre;
wire        store_addr_mis_exe_pre;

wire [31:0] inst_dec;
wire [31:0] mem_addr_exe_pre;

fetch u_fetch(
    .clk           (clk),
    .rst_b         (rst_b),
    .jump_addr_ctl (jump_addr_if_ctl),
    .jump_ctl      (jump_if_ctl),
    .hold_ctl      (hold_if_ctl),
    .clear_ctl     (clear_if_ctl),
    .inst_if_ctl   (inst_if_ctl),
    .pc_if_pre     (pc_if_pre),
    .pc_req_if_pre (pc_req_if_pre),
    .pc_if         (pc_if), 
    .inst_if       (inst_if) 
);

decoder u_decoder(
    .clk       (clk),
    .rst_b     (rst_b),
    .pc_if     (pc_if),
    .inst_if   (inst_if),
    .clear_ctl (clear_dec_ctl),
    .hold_ctl  (hold_dec_ctl),

    .pc_dec        (pc_dec       ),
    .imm_dec       (imm_dec      ),
    .imm_en_dec    (imm_en_dec   ),  
    .sll_dec       (sll_dec      ),  
    .srl_dec       (srl_dec      ),  
    .sra_dec       (sra_dec      ),  
    .add_dec       (add_dec      ),  
    .sub_dec       (sub_dec      ),  
    .lui_dec       (lui_dec      ),  
    .auipc_dec     (auipc_dec    ),  
    .xor_dec       (xor_dec      ),  
    .and_dec       (and_dec      ),  
    .or_dec        (or_dec       ),  
    .slt_dec       (slt_dec      ),  
    .sltu_dec      (sltu_dec     ),  
    .lb_dec        (lb_dec       ),  
    .lh_dec        (lh_dec       ),  
    .lbu_dec       (lbu_dec      ),  
    .lhu_dec       (lhu_dec      ),  
    .lw_dec        (lw_dec       ),  
    .sb_dec        (sb_dec       ),  
    .sh_dec        (sh_dec       ),  
    .sw_dec        (sw_dec       ),  
    .ebreak_dec    (ebreak_dec   ),  
    .ecall_dec     (ecall_dec    ),  
    .mret_dec      (mret_dec     ),  
    .jal_dec       (jal_dec      ),  
    .jalr_dec      (jalr_dec     ),  
    .beq_dec       (beq_dec      ),  
    .bne_dec       (bne_dec      ),  
    .blt_dec       (blt_dec      ),  
    .bge_dec       (bge_dec      ),  
    .bltu_dec      (bltu_dec     ),  
    .bgeu_dec      (bgeu_dec     ),  
    .fence_dec     (fence_dec    ),
    .fence_i_dec   (fence_i_dec  ),
    .csrrw_dec     (csrrw_dec    ),
    .csrrs_dec     (csrrs_dec    ),
    .csrrc_dec     (csrrc_dec    ),
    .illegal_inst_dec (illegal_inst_dec),
    .inst_dec         (inst_dec),
    .reg_raddr1_dec       (reg_raddr1_dec      ),  
    .reg_raddr2_dec       (reg_raddr2_dec      ),  
    .reg_waddr_dec        (reg_waddr_dec       ),  
    .reg_ren1_dec    (reg_ren1_dec   ),  
    .reg_ren2_dec    (reg_ren2_dec   )  
);

execute u_execute(
.clk          (clk         ),
.rst_b        (rst_b       ),
.clear_ctl    (clear_exe_ctl ),
.hold_ctl     (hold_exe_ctl  ),
.pc_dec       (pc_dec      ),
.imm_dec      (imm_dec     ),
.imm_en_dec   (imm_en_dec  ),  
.sll_dec      (sll_dec     ),  
.srl_dec      (srl_dec     ),  
.sra_dec      (sra_dec     ),  
.add_dec      (add_dec     ),  
.sub_dec      (sub_dec     ),  
.lui_dec      (lui_dec     ),  
.auipc_dec    (auipc_dec   ),  
.xor_dec      (xor_dec     ),  
.and_dec      (and_dec     ),  
.or_dec       (or_dec      ),  
.slt_dec      (slt_dec     ),  
.sltu_dec     (sltu_dec    ),  
.lb_dec       (lb_dec      ),  
.lh_dec       (lh_dec      ),  
.lbu_dec      (lbu_dec     ),  
.lhu_dec      (lhu_dec     ),  
.lw_dec       (lw_dec      ),  
.sb_dec       (sb_dec      ),  
.sh_dec       (sh_dec      ),  
.sw_dec       (sw_dec      ),  
.jal_dec      (jal_dec     ),  
.jalr_dec     (jalr_dec    ),  
.beq_dec      (beq_dec     ),  
.bne_dec      (bne_dec     ),  
.blt_dec      (blt_dec     ),  
.bge_dec      (bge_dec     ),  
.bltu_dec     (bltu_dec    ),  
.bgeu_dec     (bgeu_dec    ),  
.fence_dec    (fence_dec   ),
.fence_i_dec  (fence_i_dec ),
.csrrw_dec    (csrrw_dec   ),
.csrrs_dec    (csrrs_dec   ),
.csrrc_dec    (csrrc_dec   ),
.load_addr_mis_exe_pre (load_addr_mis_exe_pre),
.store_addr_mis_exe_pre (store_addr_mis_exe_pre),
.mem_addr_exe_pre    (mem_addr_exe_pre),
.reg_waddr_dec       (reg_waddr_dec      ),
.reg_rdata1_ctl   (reg_rdata1_ctl  ),
.reg_rdata2_ctl   (reg_rdata2_ctl  ),

.lb_exe           (lb_exe          ),
.lh_exe           (lh_exe          ),
.lbu_exe          (lbu_exe         ),
.lhu_exe          (lhu_exe         ),
.lw_exe           (lw_exe          ), 
.sb_exe           (sb_exe          ),
.sh_exe           (sh_exe          ),
.sw_exe           (sw_exe          ),

.jump_en_exe    (jump_en_exe  ),
.jump_addr_exe  (jump_addr_exe),
.reg_wen_exe      (reg_wen_exe    ),
.reg_waddr_exe      (reg_waddr_exe    ),
.reg_wdata_exe      (reg_wdata_exe    ),
.mem_addr_exe  (mem_addr_exe),
.reg_rdata2_exe   (reg_rdata2_exe ),
.csr_wen_exe  (csr_wen_exe),
.csr_waddr_exe  (csr_waddr_exe),
.csr_wdata_exe  (csr_wdata_exe),
.csr_ren_exe  (csr_ren_exe),
.csr_raddr_exe  (csr_raddr_exe),
.csr_rdata_csr  (csr_rdata_csr)

);

mem_access u_mem_access(
.clk              (clk             ),
.rst_b            (rst_b           ),
.clear_ctl        (clear_mem_ctl   ),
.hold_ctl         (hold_mem_ctl    ),
.reg_wen_exe        (reg_wen_exe       ),
.reg_waddr_exe        (reg_waddr_exe       ),
.reg_wdata_exe        (reg_wdata_exe       ),
.mem_addr_exe    (mem_addr_exe   ),
.reg_rdata2_exe     (reg_rdata2_exe    ),
.lb_exe           (lb_exe          ),
.lh_exe           (lh_exe          ),
.lbu_exe          (lbu_exe         ),
.lhu_exe          (lhu_exe         ),
.lw_exe           (lw_exe          ), 
.sb_exe           (sb_exe          ),
.sh_exe           (sh_exe          ),
.sw_exe           (sw_exe          ),
.reg_rdata2_mem     (reg_rdata2_mem    ),

.lb_mem (lb_mem ),
.lh_mem (lh_mem ),
.lbu_mem(lbu_mem),
.lhu_mem(lhu_mem),
.lw_mem(lw_mem),
.sb_mem(sb_mem),
.sh_mem(sh_mem),
.sw_mem(sw_mem),

.mem_rdata_mem_ctl    (mem_rdata_mem_ctl),
.mem_cs_en_mem_pre    (mem_cs_en_mem_pre),
.mem_wen_mem_pre    (mem_wen_mem_pre),
.mem_addr_mem_pre    (mem_addr_mem_pre),

.mem_addr_mem        (mem_addr_mem),

.mem_rdata_mem_ctl_mem    (mem_rdata_mem_ctl_mem),

.reg_wen_mem(reg_wen_mem),
.reg_waddr_mem(reg_waddr_mem),
.reg_wdata_mem(reg_wdata_mem)
);

write_back u_write_back(
.clk              (clk              ),
.rst_b            (rst_b            ),
.clear_ctl        (clear_wb_ctl        ),
.hold_ctl         (hold_wb_ctl         ),
.lb_mem           (lb_mem           ),
.lh_mem           (lh_mem           ),
.lbu_mem          (lbu_mem          ),
.lhu_mem          (lhu_mem          ),
.lw_mem           (lw_mem           ),
.sb_mem(sb_mem),
.sh_mem(sh_mem),
.sw_mem(sw_mem),
.reg_wen_mem        (reg_wen_mem        ),
.reg_waddr_mem        (reg_waddr_mem        ),
.reg_wdata_mem        (reg_wdata_mem        ),

.mem_rdata_mem_ctl_mem  (mem_rdata_mem_ctl_mem  ),
.reg_rdata2_mem  (reg_rdata2_mem  ),

.mem_addr_mem (mem_addr_mem),

.mem_addr_wb_pre  (mem_addr_wb_pre ),
.mem_wdata_wb_pre (mem_wdata_wb_pre),
.mem_wen_wb_pre   (mem_wen_wb_pre  ),
.mem_cs_en_wb_pre (mem_cs_en_wb_pre),

.reg_wdata_wb_pre(reg_wdata_wb_pre),
.reg_wen_wb(reg_wen_wb),
.reg_waddr_wb(reg_waddr_wb),
.reg_wdata_wb(reg_wdata_wb)
);

interrupt u_interrupt(
.clk                (clk               ),
.rst_b              (rst_b             ),
.ecall_dec          (ecall_dec         ),
.ebreak_dec         (ebreak_dec        ),
.mret_dec           (mret_dec          ),
.pc_dec             (pc_dec            ),
.ext_ini_flag_top (ext_ini_flag_top),
.mstatus_csr        (mstatus_csr       ),
.mie_csr            (mie_csr           ),
.mtvec_csr          (mtvec_csr         ),
.mepc_csr           (mepc_csr          ),
.csr_wen_intp     (csr_wen_intp     ),
.illegal_inst_dec   (illegal_inst_dec),
.load_addr_mis_exe_pre (load_addr_mis_exe_pre),
.store_addr_mis_exe_pre (store_addr_mis_exe_pre),
.mem_addr_exe_pre   (mem_addr_exe_pre   ),
.inst_dec           (inst_dec           ),
.csr_waddr_intp     (csr_waddr_intp     ),
.csr_wdata_intp     (csr_wdata_intp     ),
.ini_clear_intp     (ini_clear_intp     ),
.ini_jump_intp      (ini_jump_intp      ),
.ini_jump_addr_intp (ini_jump_addr_intp )
);

top_ctrl u_top_ctrl(
.clk(clk),
.rst_b(rst_b),
.jump_en_exe       (jump_en_exe       ),
.jump_addr_exe     (jump_addr_exe     ),
.ini_jump_intp     (ini_jump_intp     ),
.ini_jump_addr_intp(ini_jump_addr_intp),
.ini_clear_intp    (ini_clear_intp    ),
.ext_hold_top    (ext_hold_top    ),

.load_exe       ({lb_exe|lh_exe|lbu_exe|lhu_exe|lw_exe}      ),
.load_mem       ({lb_mem|lh_mem|lbu_mem|lhu_mem|lw_mem}      ),
.reg_rdata1_reg (reg_rdata1_reg),
.reg_rdata2_reg (reg_rdata2_reg),
.reg_wdata_exe  (reg_wdata_exe ),
.reg_wdata_mem  (reg_wdata_mem ),
.reg_wdata_wb_pre(reg_wdata_wb_pre),
.reg_wdata_wb   (reg_wdata_wb  ),
.reg_ren1_dec   (reg_ren1_dec  ),
.reg_ren2_dec   (reg_ren2_dec  ),
.reg_raddr1_dec (reg_raddr1_dec),
.reg_raddr2_dec (reg_raddr2_dec),
.reg_wen_exe    (reg_wen_exe   ),
.reg_wen_mem    (reg_wen_mem   ),
.reg_wen_wb     (reg_wen_wb    ),
.reg_waddr_exe  (reg_waddr_exe ),
.reg_waddr_mem  (reg_waddr_mem ),
.reg_waddr_wb   (reg_waddr_wb  ),
.reg_rdata1_ctl (reg_rdata1_ctl),
.reg_rdata2_ctl (reg_rdata2_ctl),

.pc_if_pre     (pc_if_pre),
.pc_req_if_pre (pc_req_if_pre),
.inst_if_ctl   (inst_if_ctl),

.mem_rdata_mem_ctl    (mem_rdata_mem_ctl),
.mem_cs_en_mem_pre    (mem_cs_en_mem_pre),
.mem_wen_mem_pre    (mem_wen_mem_pre),
.mem_addr_mem_pre    (mem_addr_mem_pre),

.mem_addr_wb_pre  (mem_addr_wb_pre ),
.mem_wdata_wb_pre (mem_wdata_wb_pre),
.mem_wen_wb_pre   (mem_wen_wb_pre  ),
.mem_cs_en_wb_pre (mem_cs_en_wb_pre),

.mem_addr_ctl  (mem_addr_ctl ),
.mem_wdata_ctl (mem_wdata_ctl),
.mem_cs_en_ctl (mem_cs_en_ctl),
.mem_wen_ctl   (mem_wen_ctl  ),
.mem_rdata_top (mem_rdata_top),

.hold_if_ctl     (hold_if_ctl     ),
.hold_dec_ctl    (hold_dec_ctl    ),
.hold_exe_ctl    (hold_exe_ctl    ),
.hold_mem_ctl    (hold_mem_ctl    ),
.hold_wb_ctl     (hold_wb_ctl     ),
.clear_if_ctl   (clear_if_ctl   ),
.clear_dec_ctl   (clear_dec_ctl   ),
.clear_exe_ctl   (clear_exe_ctl   ),
.clear_mem_ctl   (clear_mem_ctl   ),
.clear_wb_ctl    (clear_wb_ctl    ),
.jump_if_ctl     (jump_if_ctl     ),
.jump_addr_if_ctl(jump_addr_if_ctl)
);

regfile u_regfile(
.clk        (clk       ),
.rst_b      (rst_b     ),
.reg_ren1_dec (reg_ren1_dec),
.reg_ren2_dec (reg_ren2_dec),
.reg_raddr1_dec (reg_raddr1_dec),
.reg_raddr2_dec (reg_raddr2_dec),
.reg_wen_wb   (reg_wen_wb  ),
.reg_waddr_wb (reg_waddr_wb),
.reg_wdata_wb   (reg_wdata_wb  ),
.reg_rdata1_reg (reg_rdata1_reg),
.reg_rdata2_reg (reg_rdata2_reg)
);

csr_regfile u_csr_regfile(
.clk           (clk           ),
.rst_b         (rst_b         ),
.csr_wen_exe (csr_wen_exe ),
.csr_waddr_exe (csr_waddr_exe ),
.csr_wdata_exe (csr_wdata_exe ),
.csr_ren_exe (csr_ren_exe ),
.csr_raddr_exe (csr_raddr_exe ),
.csr_rdata_csr (csr_rdata_csr ),
.mstatus_csr   (mstatus_csr   ),
.mie_csr       (mie_csr       ),
.mtvec_csr     (mtvec_csr     ),
.mepc_csr      (mepc_csr      ),
.csr_wen_intp(csr_wen_intp),
.csr_waddr_intp(csr_waddr_intp),
.csr_wdata_intp(csr_wdata_intp)
);



endmodule
