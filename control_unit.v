module control_unit( input CLK,
                     input [5:0] opcode,
                     input [5:0] funct,
                     input zero,
                     input FSMRST,
                     
                     output reg RFWE,
                     output reg MWE,
                     output reg IRWE,
                     
                     output wire PCE,
                     
                     output reg [3:0] ALU_sel,
                     output reg M_to_RF_sel,
                     output reg [1:0] ALU_in_sel1,
                     output reg [1:0] ALU_in_sel2,
                     output reg RFD_sel,
                     output reg ID_sel,
                     
                     output reg [1:0] PC_sel              );
    
    // PCE is determined by a logical combination of branch, zero, and PCWE
    // The FSM should drive branch and PCWE
    reg branch;
    reg PCWE;
    assign PCE = (branch && zero) ||  PCWE;
    
    reg [1:0] ALU_op;
    
    // Opcode translations
    parameter LW = 6'b100011, SW = 6'b101011, r_type = 6'b000000, addi = 6'b001000;
    parameter BEQ = 6'b000100, J = 6'b000010;
    
    // Main Decoder
    // Implemented as a FSM
    // ----------------------------------
    // A state for each step
    reg [3:0] current_state, next_state;
    parameter fetch = 4'b0000, decode = 4'b0001, mem_addr = 4'b0010;
    parameter mem_read = 4'b0011, mem_writeback = 4'b0100, mem_enable = 4'b0101;
    parameter execute = 4'b0110, ALU_writeback = 4'b0111, branch_state = 4'b1000;
    parameter jump_state = 4'b1001, immediate = 4'b1010;
    
    // FSM should go to fetch state on reset
    // Set current states to 0 and next state to 1 on rising edge of reset signal
    always @ (posedge FSMRST) begin
        current_state = 0;
        next_state = 1;
    end
    
    // Determine Next State
    always @ (*)
        case (current_state)
            
            // S0
            fetch:
                next_state = decode;
            
            // S1
            decode:
            begin
                case (opcode)
                    
                    LW:
                        next_state = mem_addr;
                    SW:
                        next_state = mem_addr;
                        
                    r_type:
                        next_state = execute;
                        
                    J:
                        next_state = jump_state;                   
                    
                    addi:
                        next_state = mem_addr;
                        
                    BEQ:
                        next_state = branch_state;
                    
                endcase
            end
            
            // S2
            mem_addr:
            begin
                case (opcode)
                
                    SW:
                        next_state = mem_enable;
                        
                    LW:
                        next_state = mem_read;
                        
                    addi:
                        next_state = immediate;
                    
                endcase
            end
            
            // S3
            mem_read:
                next_state = mem_writeback;
                
            // S4
            mem_writeback:
                next_state = fetch;
                
            // S5
            mem_enable:
                next_state = fetch;
                
            // S6
            execute:
                next_state = ALU_writeback;
                
            // S7    
            ALU_writeback:
                next_state = fetch;
            
            // S8
            branch_state:
                next_state = fetch;
                
            // S9
            jump_state:
                next_state = fetch;
                
            // S10
            immediate:
                next_state = fetch;
       
        endcase
    
    
    // Transition to next state on rising clock edge
    always @ (posedge CLK)
        current_state <= next_state;
        
    // Set the output based only on the current state
    // Moore Machine
    always @ (*)
        case (current_state)
        
            // Fetch the next instruction from memory
            fetch:
            begin
                RFWE = 1'b0;
                MWE = 1'b0;
                IRWE = 1'b1;
                PCWE = 1'b1;
                branch = 1'b0;
                
                M_to_RF_sel = 1'bX;
                ALU_in_sel1 = 2'b00;
                ALU_in_sel2 = 2'b01;
                PC_sel = 2'b00;
                RFD_sel = 1'bX;
                ID_sel = 1'b0;
                
                ALU_op = 2'b00;
            end
                
            // Decode the fetched instruction
            decode:
            begin
                RFWE = 1'b0;
                MWE = 1'b0;
                IRWE = 1'b0;
                PCWE = 1'b0;
                branch = 1'b0;
                
                M_to_RF_sel = 1'bX;
                ALU_in_sel1 = 2'b00;
                ALU_in_sel2 = 2'b10;
                PC_sel = 2'bXX;
                RFD_sel = 1'bX;
                ID_sel = 1'bX;
                
                ALU_op = 2'b00;
            end
            
            // Compute the effective address
            // Used for immediate operations aswell
            mem_addr:
            begin
                RFWE = 1'b0;
                MWE = 1'b0;
                IRWE = 1'b0;
                PCWE = 1'b0;
                branch = 1'b0;
                
                M_to_RF_sel = 1'bX;
                ALU_in_sel1 = 2'b01;
                ALU_in_sel2 = 2'b10;
                PC_sel = 2'bXX;
                RFD_sel = 1'bX;
                ID_sel = 1'bX;
                
                ALU_op = 2'b00;
            end
                
            // Read from memory
            mem_read:
            begin
                RFWE = 1'b0;
                MWE = 1'b0;
                IRWE = 1'b0;
                PCWE = 1'b0;
                branch = 1'b0;
                
                M_to_RF_sel = 1'bX;
                ALU_in_sel1 = 2'bXX;
                ALU_in_sel2 = 2'bXX;
                PC_sel = 2'bXX;
                RFD_sel = 1'bX;
                ID_sel = 1'b1;
                
                ALU_op = 2'bXX;
            end
            
            // Write into register file
            mem_writeback:
            begin
                RFWE = 1'b1;
                MWE = 1'b0;
                IRWE = 1'b0;
                PCWE = 1'b0;
                branch = 1'b0;
                
                M_to_RF_sel = 1'b1;
                ALU_in_sel1 = 2'bXX;
                ALU_in_sel2 = 2'bXX;
                PC_sel = 2'bXX;
                RFD_sel = 1'b0;
                ID_sel = 1'bX;
                
                ALU_op = 2'bXX;
            end
            
            // Write into memory
            mem_enable:
            begin
                RFWE = 1'b0;
                MWE = 1'b1;
                IRWE = 1'b0;
                PCWE = 1'b0;
                branch = 1'b0;
                
                M_to_RF_sel = 1'bX;
                ALU_in_sel1 = 2'bXX;
                ALU_in_sel2 = 2'bXX;
                PC_sel = 2'bXX;
                RFD_sel = 1'bX;
                ID_sel = 1'b1;
                
                ALU_op = 2'bXX;
            end
            
            // Perform ALU operation based on funct
            execute:
            begin
                RFWE = 1'b0;
                MWE = 1'b0;
                IRWE = 1'b0;
                PCWE = 1'b0;
                branch = 1'b0;
                
                M_to_RF_sel = 1'bX;
                ALU_in_sel1 = 2'b01;
                ALU_in_sel2 = 2'b00;
                PC_sel = 2'bXX;
                RFD_sel = 1'bX;
                ID_sel = 1'bX;
                
                ALU_op = 2'b10;
            end
            
            // Write to register file from ALU result
            ALU_writeback:
            begin
                RFWE = 1'b1;
                MWE = 1'b0;
                IRWE = 1'b0;
                PCWE = 1'b0;
                branch = 1'b0;
                
                M_to_RF_sel = 1'b0;
                ALU_in_sel1 = 2'bXX;
                ALU_in_sel2 = 2'bXX;
                PC_sel = 2'bXX;
                RFD_sel = 1'b1;
                ID_sel = 1'bX;
                
                ALU_op = 2'bXX;
            end
            
            // Check for branch equals condition
            branch_state:
            begin
                RFWE = 1'b0;
                MWE = 1'b0;
                IRWE = 1'b0;
                PCWE = 1'b0;
                branch = 1'b1;
                
                M_to_RF_sel = 1'bX;
                ALU_in_sel1 = 2'b01;
                ALU_in_sel2 = 2'b00;
                PC_sel = 2'b01;
                RFD_sel = 1'bX;
                ID_sel = 1'bX;
                
                ALU_op = 2'b01;
            end
            
            // Store the jump address into PC
            jump_state:
            begin
                RFWE = 1'b0;
                MWE = 1'b0;
                IRWE = 1'b0;
                PCWE = 1'b1;
                branch = 1'b0;
                
                M_to_RF_sel = 1'bX;
                ALU_in_sel1 = 2'bXX;
                ALU_in_sel2 = 2'bXX;
                PC_sel = 2'b10;
                RFD_sel = 1'bX;
                ID_sel = 1'bX;
                
                ALU_op = 2'bXX;
            end
            
            // Write to register file 
            immediate:
            begin
                RFWE = 1'b1;
                MWE = 1'b0;
                IRWE = 1'b0;
                PCWE = 1'b0;
                branch = 1'b0;
                
                M_to_RF_sel = 1'b0;
                ALU_in_sel1 = 2'bXX;
                ALU_in_sel2 = 2'bXX;
                PC_sel = 2'bXX;
                RFD_sel = 1'b0;
                ID_sel = 1'bX;
                
                ALU_op = 2'bXX;
            end
            
            // Erroneous state: Disable synchronous components
            // Reset FSM
            default:
            begin
                RFWE = 1'b0;
                MWE = 1'b0;
                IRWE = 1'b0;
                PCWE = 1'b0;
                branch = 1'b0;
                
                M_to_RF_sel = 1'bX;
                ALU_in_sel1 = 2'bXX;
                ALU_in_sel2 = 2'bXX;
                PC_sel = 2'bXX;
                RFD_sel = 1'bX;
                ID_sel = 1'bX;
                
                ALU_op = 2'bXX;
                
                next_state = 0;
            end 
        endcase
        
        
        
        
        
    
    // ALU_sel values
    parameter ADD=4'b0010, SUB=4'b0000, SLL=4'b0011, LRS=4'b0100, LVLS=4'b0101, LVRS=4'b0110;
    parameter SRA=4'b0111, AND=4'b1000, OR=4'b1001, XOR=4'b1010, XNOR=4'b1011;
    
    // ALU Decoder
    always @ (opcode or funct or ALU_op) begin
    
        // Funct is irrelevant. The operation is either ADD or SUB 
        if (ALU_op[1] == 0) begin
            if (ALU_op[0] == 0)
                ALU_sel = ADD;
            else 
                ALU_sel = SUB;
        
        // ALU_op[1] is 1 so we need to look at funct for the operation
        end else begin 
            case (funct)
                
                // Only immediate shift operations should have ALU_in_sel1 = 10
                6'b000000: begin
                    ALU_sel = SLL;
                    ALU_in_sel1 = 2'b10;
                end
                
                6'b100000: ALU_sel = ADD;
                6'b100010: ALU_sel = SUB;
                6'b100100: ALU_sel = AND;
                6'b100101: ALU_sel = OR;
                6'b000100: ALU_sel = SLL;
                6'b000111: ALU_sel = SRA;
                //6'b101010: ALU_sel = SLT;
            endcase
        end
    end
endmodule
