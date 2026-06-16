module booth_ppg_8 (
    input  wire signed [7:0] b,
    input  wire              neg,
    input  wire              one,
    input  wire              two,
    output wire        [8:0] pp
);
    wire [8:0] b_ext   = {b[7], b};
    wire [8:0] b_shift = {b, 1'b0};
    wire [8:0] magnitude = two ? b_shift : one ? b_ext : 9'b0;
    assign pp = neg ? ~magnitude : magnitude;
endmodule
