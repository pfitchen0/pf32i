module ClockDivider(
    input xtal,
    input resetn,
    output clk,
    output reset
);
    parameter n = 0;

    reg [n:0] counter = 0;
    always @(posedge xtal) begin
        counter <= counter + 1;
    end

    assign clk = counter[n];
    assign reset = !resetn;
endmodule

module Memory(
    input clk,
    input [31:0] addr,
    input ren,
    output reg [31:0] rdata,
    input wen,
    input [31:0] wdata,
    input [1:0] wsize
);
    reg [31:0] mem [0:4095];  // 16kB of RAM (4 bytes per word)

    initial begin
        $readmemh("firmware.hex", mem);
    end

    wire [29:0] word_addr = addr[13:2];
    wire [31:0] word_data = mem[word_addr];
    always @(posedge clk) begin
        if (ren) begin
            rdata <= addr[1] ? (addr[0] ? (word_data >> 24) : (word_data >> 16)) :
                               (addr[0] ? (word_data >> 8) : word_data);
        end
        if (wen) begin
            case (wsize)
                2'b11: mem[word_addr] <= wdata;
                2'b10: mem[word_addr] <= addr[1] ? {wdata[15:0], word_data[15:0]} :
                                                   {word_data[31:16], wdata[15:0]};
                2'b01: mem[word_addr] <= addr[1] ? (addr[0] ? {wdata[7:0], word_data[23:0]} :
                                                              {word_data[31:24], wdata[7:0], word_data[15:0]}) :
                                                   (addr[0] ? {word_data[31:16], wdata[7:0], word_data[7:0]} :
                                                              {word_data[31:8], wdata[7:0]});
            endcase
        end
    end
endmodule

module Cpu(
    input clk,
    input reset,
    output [31:0] addr,
    output ren,
    input [31:0] rdata,
    output wen,
    output [31:0] wdata,
    output [1:0] wsize
);
    reg [31:0] pc = 32'h80000000;
    reg [31:0] instr = 32'b0000000_00000_00000_000_00000_0110011;  // NOP

    // The 10 opcodes:
    wire [6:0] opcode = instr[6:0];
    wire is_alu_reg_instr = (opcode == 7'b0110011);  // rd <- rs1 OP rs2
    wire is_alu_imm_instr = (opcode == 7'b0010011);  // rd <- rs1 OP Iimm
    wire is_branch_instr = (opcode == 7'b1100011);  // if(rs1 OP rs2) pc<-pc+Bimm
    wire is_jalr_instr = (opcode == 7'b1100111);  // rd <- pc+4; pc<-rs1+Iimm
    wire is_jal_instr = (opcode == 7'b1101111);  // rd <- pc+4; pc<-pc+Jimm
    wire is_auipc_instr = (opcode == 7'b0010111);  // rd <- pc + Uimm
    wire is_lui_instr = (opcode == 7'b0110111);  // rd <- Uimm
    wire is_load_instr = (opcode == 7'b0000011);  // rd <- mem[rs1+Iimm]
    wire is_store_instr = (opcode == 7'b0100011);  // mem[rs1+Simm] <- rs2
    wire is_system_instr = (opcode == 7'b1110011);  // FENCE, EBREAK, ECALL, etc...

    // Check for ECALL instr for testing.
    wire ecall = (instr == 32'h00000073);

    // The 5 immediate formats:
    wire [31:0] u_imm = {instr[31:12], 12'b0};
    wire [31:0] i_imm = {{21{instr[31]}}, instr[30:20]};
    wire [31:0] s_imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
    wire [31:0] b_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] j_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    // Function codes
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    // Registers
    reg [31:0] regs [0:31];
    reg [31:0] rs1;
    reg [31:0] rs2;
    wire [4:0] rd_id  = instr[11:7];
    integer i;
    initial begin
        for (i = 0; i < 32; ++i) begin
            regs[i] = 0;
        end
    end

    // ALU
    wire [31:0] alu_left = rs1;
    wire [31:0] alu_right = is_alu_reg_instr ? rs2 : i_imm;
    reg [31:0] alu_out;
    always @(*) begin
        case(funct3)
            3'b000: alu_out = (funct7[5] & instr[5]) ? (alu_left - alu_right) : (alu_left + alu_right);
            3'b001: alu_out = alu_left << alu_right[4:0];
            3'b010: alu_out = ($signed(alu_left) < $signed(alu_right));
            3'b011: alu_out = (alu_left < alu_right);
            3'b100: alu_out = (alu_left ^ alu_right);
            3'b101: alu_out = funct7[5] ? ($signed(alu_left) >>> alu_right[4:0]) : ($signed(alu_left) >> alu_right[4:0]); 
            3'b110: alu_out = (alu_left | alu_right);
            3'b111: alu_out = (alu_left & alu_right);	
        endcase
    end

    // Conditional / Branches
    reg take_branch;
    always @(*) begin
        case(funct3)
            3'b000: take_branch = (rs1 == rs2);
            3'b001: take_branch = (rs1 != rs2);
            3'b100: take_branch = ($signed(rs1) < $signed(rs2));
            3'b101: take_branch = ($signed(rs1) >= $signed(rs2));
            3'b110: take_branch = (rs1 < rs2);
            3'b111: take_branch = (rs1 >= rs2);
            default: take_branch = 1'b0;
        endcase
    end

    // Memory Access
    assign addr = (state == FETCH) ? pc : rs1 + (is_store_instr ? s_imm : i_imm);
    assign ren = (state == FETCH || (state == EXECUTE & is_load_instr));
    assign wen = (state == EXECUTE) & is_store_instr;
    assign wdata = rs2;
    assign wsize = funct3[1:0] + 1;

    // Register write back
    reg [31:0] reg_write_data;
    wire reg_wen = (state==EXECUTE && !is_branch_instr && !is_store_instr) || (state==LOAD);
    always @(*) begin
        case (1'b1)
            is_jal_instr || is_jalr_instr: reg_write_data = pc + 4;
            is_lui_instr: reg_write_data = u_imm;
            is_auipc_instr: reg_write_data = pc + u_imm;
            is_load_instr: begin
                case (funct3)
                    3'b000: reg_write_data = $signed(rdata[7:0]);
                    3'b001: reg_write_data = $signed(rdata[15:0]);
                    3'b010: reg_write_data = rdata;
                    3'b100: reg_write_data = rdata[7:0];
                    3'b101: reg_write_data = rdata[15:0];
                endcase
            end
            default: reg_write_data = alu_out;
        endcase
    end

    // Next pc
    reg [31:0] next_pc;
    always @(*) begin
        case (1'b1)
            is_branch_instr && take_branch: next_pc = pc + b_imm;
            is_jal_instr: next_pc = pc + j_imm;
            is_jalr_instr: next_pc = rs1 + i_imm;
            default: next_pc = pc + 4;
        endcase
    end

    // State Machine
    localparam FETCH = 0;
    localparam DECODE = 1;
    localparam EXECUTE = 2;
    localparam LOAD = 3;
    reg [1:0] state = FETCH;

    always @(posedge clk) begin
        if (reset) begin
            pc <= 32'h80000000;
            state <= FETCH;
        end else begin
            if (reg_wen && rd_id != 0) begin
                regs[rd_id] <= reg_write_data;
            end
            case (state)
                FETCH: begin
                    state <= DECODE;
                end
                DECODE: begin
                    instr <= rdata;
                    rs1 <= regs[rdata[19:15]];
                    rs2 <= regs[rdata[24:20]];
                    state <= EXECUTE;
                end
                EXECUTE: begin
                    pc <= next_pc;
                    state <= is_load_instr  ? LOAD : FETCH;
                    // Exit state is ECALL with code 93 in a7
                    if (ecall && (/*a7*/regs[17] == 93)) begin
                        // Pass
                        if ((/*gp*/regs[3] == 1) && (/*a0*/regs[10] == 0)) begin
                            $display("pc = 0x%04x", pc);
                            $display("PASS");
                        // Fail
                        end else begin
                            $display("test %0d failed", /*gp*/regs[3] >> 1);
                            $display("pc = 0x%04x", pc);
                            $display("FAIL");
                        end
                        $finish();
                    end
                end
                LOAD: begin
                    state <= FETCH;
                end
            endcase
        end
    end  // always @(posedge clk)

endmodule

module Gpio (
    input clk,
    input wen,
    input [31:0] wdata,
    output reg [7:0] gpio
);
    always @(posedge clk) begin
        if (wen) begin
            gpio <= wdata;
        end
    end

endmodule

module Soc (
    input xtal,
    input resetn,
    output [7:0] gpio
);
    wire clk;
    wire reset;

    ClockDivider clk_divider (
        .xtal(xtal),
        .resetn(resetn),
        .clk(clk),
        .reset(reset)
    );

    wire [31:0] addr;
    wire ren;
    wire [31:0] rdata;
    wire wen;
    wire [31:0] wdata;
    wire [1:0] wsize;

    // Memory mapped GPIO
    wire is_gpio = addr[30];  // Address base of 0x40000000

    Gpio gpio_mod (
        .clk(clk),
        .wen(is_gpio & wen),
        .wdata(wdata),
        .gpio(gpio)
    );

    Memory memory (
        .clk(clk),
        .addr(addr),
        .ren((!is_gpio) & ren),
        .rdata(rdata),
        .wen((!is_gpio) & wen),
        .wdata(wdata),
        .wsize(wsize)
    );

    Cpu cpu (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .ren(ren),
        .rdata(rdata),
        .wen(wen),
        .wdata(wdata),
        .wsize(wsize)
    );

endmodule
