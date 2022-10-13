module ALU(input [3:0] ALU_sel,
           input [31:0] ALU_in1, ALU_in2,
           output wire zero,
           output reg [31:0] ALU_out        );
           
    parameter ADD=4'b0010, SUB=4'b0000, SLL=4'b0011, LRS=4'b0100, LVLS=4'b0101, LVRS=4'b0110;
    parameter SRA=4'b0111, AND=4'b1000, OR=4'b1001, XOR=4'b1010, XNOR=4'b1011;
    always @ (ALU_in1 or ALU_in2 or ALU_sel)
        case(ALU_sel)
            ADD : ALU_out = ALU_in1 + ALU_in2;
            SUB : ALU_out = ALU_in1 - ALU_in2;
            //SLL : ALU_out = ALU_in1 << 1;
            //LRS : ALU_out = ALU_in1 >> 1;
            SLL : ALU_out = ALU_in2 << ALU_in1;
            //LVRS : ALU_out = ALU_in1 >> ALU_in2;
            SRA : ALU_out = ALU_in2 >>> ALU_in1;
            AND : ALU_out = ALU_in1 & ALU_in2;
            OR : ALU_out = ALU_in1 | ALU_in2;
            XOR : ALU_out = ALU_in1 ^ ALU_in2;
            //XNOR : ALU_out = ALU_in1 ~^ ALU_in2;
            default : ALU_out = 0;
         endcase
    
    // Asynchronously drive output zero to 1 when ALU_out is 0   
    assign zero = ALU_out ? 0 : 1;
    
endmodule
