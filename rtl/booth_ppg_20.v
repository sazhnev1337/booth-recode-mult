module booth_ppg_20 (
    input  wire signed [19:0] b,
    input  wire               neg,
    input  wire               one,
    input  wire               two,
    output wire        [20:0] pp
);
    wire [20:0] b_ext   = {b[19], b};
    wire [20:0] b_shift = {b, 1'b0};
    wire [20:0] magnitude = two ? b_shift : one ? b_ext : 21'b0;
    assign pp = neg ? ~magnitude : magnitude;
endmodule
