`timescale 1ns / 1ps
module multicycle_processor_tb;

    reg CLK, RST;
    
    multicycle_processor DUT(   .CLK(CLK),
                                .RST(RST)    );
    
    // Initialize and start the clock                      
    initial CLK = 0;
    always #100 CLK = ~CLK;
    
    // Activate reset signals 
    // before first clock cycle ends
    initial begin
        RST = 1;
        #50;
        RST = 0;
    end 
endmodule