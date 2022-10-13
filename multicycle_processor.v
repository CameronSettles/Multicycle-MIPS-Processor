module multicycle_processor(input CLK,
                            input RST  );
     
    wire RFWE, MWE, IRWE, PCE;
    wire [3:0] ALU_sel;
    wire [5:0] opcode, funct;
    
    wire [1:0] ALU_in_sel1, ALU_in_sel2, PC_sel;
    wire M_to_RF_sel, RFD_sel, ID_sel;
    
    wire zero;
     
     
         
     control_unit CU (  .CLK(CLK),
                        .opcode(opcode),
                        .funct(funct),
                        .zero(zero),
                        .FSMRST(RST),
                     
                        .RFWE(RFWE),
                        .MWE(MWE),
                        .IRWE(IRWE),
                     
                        .PCE(PCE),
                     
                        .ALU_sel(ALU_sel),
                        .M_to_RF_sel(M_to_RF_sel),
                        .ALU_in_sel1(ALU_in_sel1),
                        .ALU_in_sel2(ALU_in_sel2),
                        .RFD_sel(RFD_sel),
                        .ID_sel(ID_sel),
                     
                        .PC_sel(PC_sel)       );
                        
                        
    datapath DP (   .CLK(CLK),

                    .MWE(MWE),
                    .RFWE(RFWE),
                    .PCE(PCE),
                    .IRWE(IRWE),
                 
                    .MRST(RST),
                    .RFRST(RST),
                    .PCRRST(RST),
                    .IRRST(RST),
                    .DRRST(RST),
                    .RF_out1_reg_RST(RST),
                    .RF_out2_reg_RST(RST),
                    .ALU_out_reg_RST(RST),
                 
                    .ALU_sel(ALU_sel),
                    .M_to_RF_sel(M_to_RF_sel),
                    .ALU_in_sel1(ALU_in_sel1),
                    .ALU_in_sel2(ALU_in_sel2),
                    .PC_sel(PC_sel),
                    .RFD_sel(RFD_sel),
                    .ID_sel(ID_sel),
                 
                    .opcode_out(opcode),
                    .funct_out(funct),
                    .zero_out(zero)         );
                                 
                            
                            
                            
endmodule
