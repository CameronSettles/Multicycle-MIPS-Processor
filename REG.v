module REG   #( parameter RST_VAL = 0   )
              ( input CLK,
                input EN,
                input RST,
                input [31:0] in,
                output wire [31:0] out  );
    
    reg [31:0] mem;
    
    // Asynchronous reset
    always @ (posedge RST)
        mem = RST_VAL;
        
    // Synchronous read
    always @ (posedge CLK)
        if (EN)
            mem <= in;
    
    // Asynchronously drive output signal
    assign out = mem;
        
endmodule
