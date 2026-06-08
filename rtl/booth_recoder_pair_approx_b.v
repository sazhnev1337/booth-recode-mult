module booth_recoder_pair_approx_b (
    input  wire [4:0] window,
    output wire       neg_lo,
    output wire       one_lo,
    output wire       two_lo,
    output wire       neg_hi,
    output wire       one_hi,
    output wire       two_hi,
    output wire       pattern_detected   // 1, если на окне сработал approx-паттерн (AK1 или AK2)
);

    wire a_m1 = window[0];
    wire a_0  = window[1];
    wire a_1  = window[2];
    wire a_2  = window[3];
    wire a_3  = window[4];

    wire [2:0] triplet_lo = {a_1, a_0, a_m1};
    wire [2:0] triplet_hi = {a_3, a_2, a_1};

    wire neg_lo_raw = triplet_lo[2];
    wire one_lo_raw = triplet_lo[1] ^ triplet_lo[0];
    wire two_lo_raw = ( triplet_lo[2] & ~triplet_lo[1] & ~triplet_lo[0])
                    | (~triplet_lo[2] &  triplet_lo[1] &  triplet_lo[0]);

    wire neg_hi_raw = triplet_hi[2];
    wire one_hi_raw = triplet_hi[1] ^ triplet_hi[0];
    wire two_hi_raw = ( triplet_hi[2] & ~triplet_hi[1] & ~triplet_hi[0])
                    | (~triplet_hi[2] &  triplet_hi[1] &  triplet_hi[0]);

    wire ak1 = ~a_3 & ~a_2 &  a_1 & ~(a_0 & a_m1);
    wire ak2 =  a_3 &  a_2 & ~a_1 & (a_0 | a_m1);

    wire recode = ak1 | ak2;

    assign neg_lo = recode ? ak2  : neg_lo_raw;
    assign one_lo = recode ? 1'b0 : one_lo_raw;
    assign two_lo = recode ? 1'b1 : two_lo_raw;

    assign neg_hi = recode ? 1'b0 : neg_hi_raw;
    assign one_hi = recode ? 1'b0 : one_hi_raw;
    assign two_hi = recode ? 1'b0 : two_hi_raw;

    assign pattern_detected = recode;

endmodule
