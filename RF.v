module RF( input CLK,
           input RST,
           input RFWE,
           input [4:0] RFRA1,
           input [4:0] RFRA2,
           input [4:0] RFWA,
           input [31:0] RFWD,
           output wire [31:0] RFRD1,
           output wire [31:0] RFRD2 );
    
    // Register File holds 32 words by default
    parameter DEPTH = 31;
    reg [31:0] mem [0:DEPTH];
    
    // On reset: set all registers to 0
    integer i;
    always @ (posedge RST) begin
        for (i = 0; i < DEPTH+1; i = i + 1) begin
            mem[i]= 0;
        end
    end
     
    // Read from RF at RFRD1 and RFRD2 before writing
    assign RFRD1 = mem[RFRA1];
    assign RFRD2 = mem[RFRA2];
    
    // The RF is in read-first mode
    always @ (posedge CLK) begin
        
        // Synchronously write RFWD to RF at RFRA if write enable (RFWE) is active
        if (RFWE)
            mem[RFWA] <= RFWD;
    end
endmodule
