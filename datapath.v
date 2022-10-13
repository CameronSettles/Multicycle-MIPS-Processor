module datapath( input CLK,

                 input MWE,
                 input RFWE,
                 input PCE,
                 input IRWE,
                 
                 input MRST,
                 input RFRST,
                 input PCRRST,
                 input IRRST,
                 input DRRST,
                 input RF_out1_reg_RST,
                 input RF_out2_reg_RST,
                 input ALU_out_reg_RST,
                 
                 input [3:0] ALU_sel,
                 input M_to_RF_sel,
                 input [1:0] ALU_in_sel1,
                 input [1:0] ALU_in_sel2,
                 input [1:0] PC_sel,
                 input RFD_sel,
                 input ID_sel,
                 
                 output wire [5:0] opcode_out,
                 output wire [5:0] funct_out,
                 output wire zero_out            );
    
    // ----------------------------  INSTRUCTION  --------------------------------------
    // Instructions are 32 bits
    wire [31:0] inst;
    // Disecting the instruction into its constituent parts:
    // -----------------------------------------------------
    // First 6 bits are the opcode
    wire [5:0] opcode = inst[31:26];
    // The next three 5-bit sections could be rs and rt 
    // respectively if the instruction is R-type or I-type.
    wire [4:0] rs = inst[25:21];
    wire [4:0] rt = inst[20:16];
    // If the instruction is R-type:
    // the next two 5-bit sections are rd and shamt
    // and the last 6-bit section is funct
    wire [4:0] rd = inst[15:11];
    wire [4:0] shamt = inst[10:6];
    wire [5:0] funct = inst[5:0];
    // If the instruction is I-type:
    // the last 16-bit section is an immediate (imm) 
    wire [15:0] imm = inst[15:0];
    // If the instruction is J-type:
    // the 26-bit section after the opcode is a jump target (jaddr)
    wire [25:0] jaddr = inst[25:0];
    
    // Output the instruction opcode and funct fields for the control unit
    assign opcode_out = opcode;
    assign funct_out = funct;
    
    // Construct Sign-Extended Immediate (Simm)
    wire [31:0] Simm;
    assign Simm[31:0] = { {16{inst[15]}}, imm[15:0] };
    
    
    // ----------------------------  PROGRAM COUNTER  --------------------------------------
    // PC holds the address of the current instuction in IM
    wire [31:0] PC;
    // Program Counter Prime (PCP)(PC') is the address of the next instruction in IM
    reg [31:0] PCP;
    //   1.   PCP becomes PC_branch if there is a branch instruction
    //   2.   PCP becomes PC_jump if there is a jump instruction
    //   3.   Otherwise PCP becomse PC_p1
    wire [31:0] PC_p1, PC_branch, PC_jump;
      
    // PC_p1 is PC + 1
    assign PC_p1 = PC + 1;
    
    // PC_branch is PC + 1 + Simm
    assign PC_branch = PC_p1 + Simm;
    
    // PC_jump keeps the 6 MSBs of PC + 1 and replaces the rest with jaddr
    // Then offsets address by 1024 to access the instruction part of memory
    assign PC_jump = {PC_p1[31:26], jaddr[25:0]} + 1024;
    
    
    // ----------------------------  INTERMEDIATE WIRES  --------------------------------------
    // Synchronous Components' Outputs
    wire [31:0] RFRD1;
    wire [31:0] RFRD2;
    wire [31:0] MEM_out;
    wire [31:0] ALU_out;
    
    // Multicycle Registers' Outputs
    wire [31:0] ALU_out_reg_out;
    wire [31:0] RF_out1_reg_out;
    wire [31:0] RF_out2_reg_out;
    wire [31:0] DR_out;
    
   
    // ----------------------------  DATAPATH  --------------------------------------
    
    // PCP MUX
    always @ (PC_sel or ALU_out or ALU_out_reg_out or PC_jump) begin
        if (PC_sel == 0) 
            PCP = ALU_out;
        else if (PC_sel == 1)
            PCP = ALU_out_reg_out;
        else if (PC_sel == 2)
            PCP = PC_jump;
    end
    
    
    // address MUX
    reg [31:0] address;
    always @ (ID_sel or PC or ALU_out_reg_out) begin
        if (ID_sel == 0)
            address = PC;
        else
            address = ALU_out_reg_out;
    end
    
    MEM mem(.CLK(CLK),
            .RST(MRST),
            .MWE(MWE),
            .MRA(address),
            .MWD(RF_out2_reg_out),
            .MRD(MEM_out) );
         
    // ALUDM MUX
    reg [31:0] ALUDM;
    always @ (M_to_RF_sel or ALU_out_reg_out or DR_out) begin
        if (M_to_RF_sel == 0)
            ALUDM = ALU_out_reg_out;
        else
            ALUDM = DR_out;
    end
    
    // RFD MUX
    reg [31:0] rtd;
    always @ (RFD_sel or rt or rd) begin
        if (RFD_sel == 0)
            rtd = rt;
        else
            rtd = rd;
    end
    
    RF reg_file(.CLK(CLK),
                .RST(RFRST),
                .RFWE(RFWE),
                .RFRA1(rs),
                .RFRA2(rt),
                .RFWA(rtd),
                .RFWD(ALUDM),
                .RFRD1(RFRD1),
                .RFRD2(RFRD2)  );
    
    // Sign extend shamt
    wire [31:0] Sshamt;
    assign Sshamt[31:0] = { {26{inst[10]}}, shamt[4:0]};
    
    // ALU_in1 MUX
    // select Sshamt for immediate shift operations
    // select PC for calculating PC + 1
    reg [31:0] ALU_in1;
    always @ (ALU_in_sel1 or PC or RF_out1_reg_out or Sshamt) begin
        if  (ALU_in_sel1 == 0)
            ALU_in1 = PC;
        else if (ALU_in_sel1 == 1)
            ALU_in1 = RF_out1_reg_out;
        else if (ALU_in_sel1 == 2)
            ALU_in1 = Sshamt;
    end
    
    // ALU_in2 MUX
    reg [31:0] ALU_in2;
    always @ (ALU_in_sel2 or RF_out2_reg_out or Simm) begin
        if (ALU_in_sel2 == 0)
            ALU_in2 = RF_out2_reg_out;
        else if (ALU_in_sel2 == 1)
            ALU_in2 = 1;
        else if (ALU_in_sel2 == 2)
            ALU_in2 = Simm;
    end
    
    ALU alu(.ALU_sel(ALU_sel),
            .ALU_in1(ALU_in1),
            .ALU_in2(ALU_in2),
            .zero(zero_out),
            .ALU_out(ALU_out) );
            
    
    
    REG #(  .RST_VAL(1024)  ) PC_reg
         (  .CLK(CLK),
            .RST(PCRRST),
            .EN(PCE),
            .in(PCP),
            .out(PC)        );   
                
    REG inst_reg(   .CLK(CLK),
                    .RST(IRRST),
                    .EN(IRWE),
                    .in(MEM_out),
                    .out(inst)       );
    
    
    REG data_reg(   .CLK(CLK),
                    .RST(DRRST),
                    .EN(1),
                    .in(MEM_out),
                    .out(DR_out)       );
                  
    
    REG RF_out1_reg(.CLK(CLK),
                    .RST(RF_out1_reg_RST),
                    .EN(1),
                    .in(RFRD1),
                    .out(RF_out1_reg_out)       );
                    
    
    REG RF_out2_reg(.CLK(CLK),
                    .RST(RF_out2_reg_RST),
                    .EN(1),
                    .in(RFRD2),
                    .out(RF_out2_reg_out)       );
                    
    
    REG ALU_out_reg(.CLK(CLK),
                    .RST(ALU_out_reg_RST),
                    .EN(1),
                    .in(ALU_out),
                    .out(ALU_out_reg_out)       );             
             
endmodule
