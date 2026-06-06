module booth_recoder_pair_approx (
    input  wire [4:0] window,
    output wire       neg_lo,
    output wire       one_lo,
    output wire       two_lo,
    output wire       neg_hi,
    output wire       one_hi,
    output wire       two_hi
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

    // AK1 срабатывает на 00100, 00101, 00110 — даёт K_lo = +2.
    // Это три паттерна, у которых старшие три бита = 001, а младшие два — не оба единицы.
    // Точнее по формуле (9): ~a_3 & ~a_2 & a_1 & ~(a_0 & a_m1).
    wire ak1 = ~a_3 & ~a_2 &  a_1 & ~(a_0 & a_m1);

    // AK2 срабатывает на 11011, 11010, 11001 — даёт K_lo = -2.
    // По формуле (9): a_3 & a_2 & ~a_1 & ~(~a_0 & ~a_m1), то есть a_3 & a_2 & ~a_1 & (a_0 | a_m1).
    wire ak2 =  a_3 &  a_2 & ~a_1 &  (a_0 | a_m1);

    wire recode = ak1 | ak2;

    // При срабатывании:
    //   позиция 2k:   K_lo = +2 (если ak1) или -2 (если ak2)  =>  two=1, one=0, neg=ak2
    //   позиция 2k+1: K_hi = 0                                 =>  neg=0, one=0, two=0
    assign neg_lo = recode ? ak2  : neg_lo_raw;
    assign one_lo = recode ? 1'b0 : one_lo_raw;
    assign two_lo = recode ? 1'b1 : two_lo_raw;

    assign neg_hi = recode ? 1'b0 : neg_hi_raw;
    assign one_hi = recode ? 1'b0 : one_hi_raw;
    assign two_hi = recode ? 1'b0 : two_hi_raw;

endmodule