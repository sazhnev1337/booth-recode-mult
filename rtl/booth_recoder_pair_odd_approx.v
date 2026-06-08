module booth_recoder_pair_odd_approx (
    input  wire [4:0] window,
    input  wire       enable,
    output wire       neg_lo,
    output wire       one_lo,
    output wire       two_lo,
    output wire       neg_hi,
    output wire       one_hi,
    output wire       two_hi,
    output wire       pattern_detected
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

    wire recode_raw = ak1 | ak2;
    wire recode_eff = recode_raw & enable;

    // ak2_eff нужен для определения знака K_lo при срабатывании.
    // При recode_eff=0 значение не используется.
    wire ak2_eff = ak2 & enable;

    assign neg_lo = recode_eff ? ak2_eff : neg_lo_raw;
    assign one_lo = recode_eff ? 1'b0    : one_lo_raw;
    assign two_lo = recode_eff ? 1'b1    : two_lo_raw;

    assign neg_hi = recode_eff ? 1'b0 : neg_hi_raw;
    assign one_hi = recode_eff ? 1'b0 : one_hi_raw;
    assign two_hi = recode_eff ? 1'b0 : two_hi_raw;

    assign pattern_detected = recode_eff;

endmodule
