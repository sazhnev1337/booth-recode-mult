module booth_encoder (
    input  wire [2:0] triplet,    // {a[2i+1], a[2i], a[2i-1]}
    output wire       neg,        // знак: 1 = брать -B/-2B
    output wire       one,        // |M| == 1 -> кратное ±B
    output wire       two          // |M| == 2 -> кратное ±2B
);

    wire a_high = triplet[2];     // a[2i+1]
    wire a_mid  = triplet[1];     // a[2i]
    wire a_low  = triplet[0];     // a[2i-1]

    assign neg = a_high;
    assign one = a_mid ^ a_low;
    assign two = (a_high & ~a_mid & ~a_low) | (~a_high & a_mid & a_low);

endmodule