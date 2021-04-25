`timescale 1ns / 1ps

module morse_decoder_application(
    input b_noisy, clk, reset_n,
    output [7:0] AN,
    output [6:0] sseg,
    output DP
    );
    
    wire b, b_edge, dot, dash;
    wire [4:0] Q;
    wire [5:0] I7, I4, I3, I2, I1, I0;
    reg [4:0] enable;
    wire [2:0] count;
    
    debouncer_delayed b_debounce(
        .clk(clk),
        .reset_n(reset_n),
        .noisy(b_noisy),
        .debounced(b)
    );
    
    //used to test shift register and 7seg
//    edge_detector edge_b(
//        .clk(clk),
//        .reset_n(reset_n),
//        .level(b),
//        .p_edge(b_edge)
//    );
    
    morse_decoder morse(
        .b(b),
        .clk(clk),
        .reset_n(reset_n),
        .dot(dot),
        .dash(dash)
    );
    
    shift_register left_shift(
        .clk(clk),
        .reset_n(reset_n),
        .shift(dot^dash),
        .SI(dash),
        .Q(Q)
    );
    
    udl_counter #(.BITS(3)) digit_count(
        .clk(clk),
        .reset_n(reset_n),
        .enable(dot^dash),
        .up(1),
        .load(count == 5),
        .D(0),
        .Q(count)
    );
    
    //determine which 7segs are enabled from count
    always@(count)
    begin
        case(count)
            0: enable = 5'b00000;
            1: enable = 5'b00001;
            2: enable = 5'b00011;
            3: enable = 5'b00111;
            4: enable = 5'b01111;
            5: enable = 5'b11111;
            default: enable = 5'b00000;
        endcase
    end
    
    assign I7 = {1'b1, {1'b0, count}, 1'b1};
    assign I4 = {enable[4], {3'b0, Q[4]}, 1'b1};
    assign I3 = {enable[3], {3'b0, Q[3]}, 1'b1};
    assign I2 = {enable[2], {3'b0, Q[2]}, 1'b1};
    assign I1 = {enable[1], {3'b0, Q[1]}, 1'b1};
    assign I0 = {enable[0], {3'b0, Q[0]}, 1'b1};
    
    sseg_driver driver (
        .I0(I0),
        .I1(I1),
        .I2(I2),
        .I3(I3),
        .I4(I4),
        .I7(I7),
        .clk(clk),
        .AN(AN),
        .bcd(sseg),
        .DP(DP)
    );
    
endmodule
