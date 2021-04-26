`timescale 1ns / 1ps

module morse_decoder
    //50ms delay
    #(parameter time_unit = 4_999_999, BITS = 3)(
    input b, clk, reset_n,
    output dot, dash, lg, wg
    );
    
    wire done;
    wire [BITS-1:0] Q;
    reg [2:0] state_reg, state_next;
    
    localparam s0=0, s1=1, s2=2, s3=3, s4=4;
    
    //100ms timer. output used to increment counter
    timer_parameter #(.FINAL_VALUE(time_unit)) morse_time(
        .clk(clk),
        .reset_n(b),
        .enable(b),
        .done(done)    
    );
    
    //counts time units that have passed
    udl_counter #(.BITS(BITS)) unit_counter(
        .clk(clk),
        .reset_n(b),
        .enable(done),
        .up(1),
        .load(0),
        .D(0),
        .Q(Q)
    );
    
    always @(posedge clk, negedge reset_n)
    begin
        if(~reset_n)
            state_reg <= 0;
        else
            state_reg <= state_next;
    end
    
    //FSM to handle dot or dash
    //0 time units, no output. 1-2 is dot, 3-4 is dash.
    always @*
    begin
        case(state_reg)
            s0: case(Q)
                3'b001: state_next = s1;
                default: state_next = s0;
            endcase
            
            s1: case(Q)
                3'b000: state_next = s0;
                3'b001: state_next = s1;
                3'b010: state_next = s2;
                default: state_next = s0;
            endcase
            
            s2: case(Q)
                3'b000: state_next = s0;
                3'b010: state_next = s2;
                3'b011: state_next = s3;
                default: state_next = s0;
            endcase   
            
            s3: case(Q)
                3'b000: state_next = s0;
                3'b011: state_next = s3;
                3'b100: state_next = s4;
                default: state_next = s0;
            endcase 
            
            s4: case(Q)
                3'b000: state_next = s0;
                3'b100: state_next = s4;
                default: state_next = s0;
            endcase 
        endcase
    end
    
    assign dot = (state_reg == s1)&(Q == 3'b000) |
                 (state_reg == s2)&(Q == 3'b000);
                 
    assign dash = (state_reg == s3)&(Q == 3'b000) |
                  (state_reg == s4)&(Q == 3'b000);
    
endmodule
