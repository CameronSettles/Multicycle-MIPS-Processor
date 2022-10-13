module MEM( input CLK,
            input RST,
            input MWE,
            input [31:0] MRA,
            input [31:0] MWD,
           output wire [31:0] MRD
    );
    
    // Memory (MEM) is split into Data Memory (DM) and Instruction Memory (IM)
    parameter DEPTH = 2048;
    reg [31:0] mem [0:DEPTH];
    
    // Load instructions into the bottom half of MEM
    initial $readmemb("part_e.mem", mem, DEPTH/2);
    
    // On reset: set all register to 0
    integer i;
    always @ (posedge RST) begin
        for (i = 0; i < (DEPTH/2); i = i + 1) begin
            mem[i]= 0;
        end
        // Load MEM with 17, 31, -5, -2, 250
        mem[0] = 17;
        mem[1] = 31;
        mem[2] = -5;
        mem[3] = -2;
        mem[4] = 250;
    end
    
    // Asynchronously read
    assign MRD = mem[MRA];

    // The MEM is in read-first mode
    always @ (posedge CLK) begin
        // Synchronously write MWD into MEM at MRA if write enable (MWE) is active
        if (MWE)
            mem[MRA] <= MWD;
    end
endmodule
