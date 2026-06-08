module booth_recoder_pair_exact_b (
    input  wire [4:0] window,
    output wire       neg_lo,
    output wire       one_lo,
    output wire       two_lo,
    output wire       neg_hi,
    output wire       one_hi,
    output wire       two_hi,
    output wire       pattern_detected   // 1, если на окне сработал exact-паттерн
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

    wire pat_00100 = ~a_3 & ~a_2 &  a_1 & ~a_0 & ~a_m1;
    wire pat_11011 =  a_3 &  a_2 & ~a_1 &  a_0 &  a_m1;
    wire recode    = pat_00100 | pat_11011;

    assign neg_lo = recode ? ~neg_lo_raw : neg_lo_raw;
    assign one_lo = recode ? 1'b0        : one_lo_raw;
    assign two_lo = recode ? 1'b1        : two_lo_raw;

    assign neg_hi = recode ? 1'b0 : neg_hi_raw;
    assign one_hi = recode ? 1'b0 : one_hi_raw;
    assign two_hi = recode ? 1'b0 : two_hi_raw;

    // Новый выход: индикатор срабатывания паттерна для арбитража уровня B.
    assign pattern_detected = recode;

endmodule
