module booth_multiplier_exact_recoded_b (
    input  wire signed [15:0] a,
    input  wire signed [15:0] b,
    output wire signed [31:0] p
);

    wire [16:0] a_ext = {a, 1'b0};

    // ---- 4 чётные пары: покрывают (0,1), (2,3), (4,5), (6,7) ----
    wire neg_even_lo [0:3];
    wire one_even_lo [0:3];
    wire two_even_lo [0:3];
    wire neg_even_hi [0:3];
    wire one_even_hi [0:3];
    wire two_even_hi [0:3];
    wire pd_even     [0:3];

    genvar k;
    generate
        for (k = 0; k < 4; k = k + 1) begin : even_pair
            booth_recoder_pair_exact_b rec_e (
                .window           (a_ext[4*k+4 : 4*k]),
                .neg_lo           (neg_even_lo[k]),
                .one_lo           (one_even_lo[k]),
                .two_lo           (two_even_lo[k]),
                .neg_hi           (neg_even_hi[k]),
                .one_hi           (one_even_hi[k]),
                .two_hi           (two_even_hi[k]),
                .pattern_detected (pd_even[k])
            );
        end
    endgenerate

    // ---- enable для нечётных пар: активна только если обе соседние чётные не сработали ----
    wire enable_odd [0:2];
    assign enable_odd[0] = ~pd_even[0] & ~pd_even[1];
    assign enable_odd[1] = ~pd_even[1] & ~pd_even[2];
    assign enable_odd[2] = ~pd_even[2] & ~pd_even[3];

    // ---- 3 нечётные пары: покрывают (1,2), (3,4), (5,6) ----
    // Окна нечётных: a_ext[4l+6 : 4l+2].
    wire neg_odd_lo [0:2];
    wire one_odd_lo [0:2];
    wire two_odd_lo [0:2];
    wire neg_odd_hi [0:2];
    wire one_odd_hi [0:2];
    wire two_odd_hi [0:2];
    wire pd_odd     [0:2];

    genvar l;
    generate
        for (l = 0; l < 3; l = l + 1) begin : odd_pair
            booth_recoder_pair_odd_exact rec_o (
                .window           (a_ext[4*l+6 : 4*l+2]),
                .enable           (enable_odd[l]),
                .neg_lo           (neg_odd_lo[l]),
                .one_lo           (one_odd_lo[l]),
                .two_lo           (two_odd_lo[l]),
                .neg_hi           (neg_odd_hi[l]),
                .one_hi           (one_odd_hi[l]),
                .two_hi           (two_odd_hi[l]),
                .pattern_detected (pd_odd[l])
            );
        end
    endgenerate

    // ---- Per-позиция выбор источника: чётная (приоритет) или нечётная ----
    wire        neg [0:7];
    wire        one [0:7];
    wire        two [0:7];

    // Позиция 0: только чётная k=0 lo.
    assign neg[0] = neg_even_lo[0];
    assign one[0] = one_even_lo[0];
    assign two[0] = two_even_lo[0];

    // Позиция 1: чётная k=0 hi vs нечётная l=0 lo. sel = pd_odd[0].
    assign neg[1] = pd_odd[0] ? neg_odd_lo[0] : neg_even_hi[0];
    assign one[1] = pd_odd[0] ? one_odd_lo[0] : one_even_hi[0];
    assign two[1] = pd_odd[0] ? two_odd_lo[0] : two_even_hi[0];

    // Позиция 2: чётная k=1 lo vs нечётная l=0 hi. sel = pd_odd[0].
    assign neg[2] = pd_odd[0] ? neg_odd_hi[0] : neg_even_lo[1];
    assign one[2] = pd_odd[0] ? one_odd_hi[0] : one_even_lo[1];
    assign two[2] = pd_odd[0] ? two_odd_hi[0] : two_even_lo[1];

    // Позиция 3: чётная k=1 hi vs нечётная l=1 lo. sel = pd_odd[1].
    assign neg[3] = pd_odd[1] ? neg_odd_lo[1] : neg_even_hi[1];
    assign one[3] = pd_odd[1] ? one_odd_lo[1] : one_even_hi[1];
    assign two[3] = pd_odd[1] ? two_odd_lo[1] : two_even_hi[1];

    // Позиция 4: чётная k=2 lo vs нечётная l=1 hi. sel = pd_odd[1].
    assign neg[4] = pd_odd[1] ? neg_odd_hi[1] : neg_even_lo[2];
    assign one[4] = pd_odd[1] ? one_odd_hi[1] : one_even_lo[2];
    assign two[4] = pd_odd[1] ? two_odd_hi[1] : two_even_lo[2];

    // Позиция 5: чётная k=2 hi vs нечётная l=2 lo. sel = pd_odd[2].
    assign neg[5] = pd_odd[2] ? neg_odd_lo[2] : neg_even_hi[2];
    assign one[5] = pd_odd[2] ? one_odd_lo[2] : one_even_hi[2];
    assign two[5] = pd_odd[2] ? two_odd_lo[2] : two_even_hi[2];

    // Позиция 6: чётная k=3 lo vs нечётная l=2 hi. sel = pd_odd[2].
    assign neg[6] = pd_odd[2] ? neg_odd_hi[2] : neg_even_lo[3];
    assign one[6] = pd_odd[2] ? one_odd_hi[2] : one_even_lo[3];
    assign two[6] = pd_odd[2] ? two_odd_hi[2] : two_even_lo[3];

    // Позиция 7: только чётная k=3 hi.
    assign neg[7] = neg_even_hi[3];
    assign one[7] = one_even_hi[3];
    assign two[7] = two_even_hi[3];

    // ---- 8 PPG (обычные, без zeroed) ----
    wire [16:0] pp [0:7];
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ppg_lane
            booth_ppg ppg (
                .b   (b),
                .neg (neg[i]),
                .one (one[i]),
                .two (two[i]),
                .pp  (pp[i])
            );
        end
    endgenerate

    // ---- Знаковое расширение строк ----
    wire signed [31:0] row [0:7];
    generate
        for (i = 0; i < 8; i = i + 1) begin : row_build
            assign row[i] = $signed(pp[i]) <<< (2*i);
        end
    endgenerate

    // ---- Neg-коррекция (как в level A, без маскирования) ----
    wire signed [31:0] neg_correction;
    assign neg_correction = { 16'b0,
                              1'b0, neg[7],
                              1'b0, neg[6],
                              1'b0, neg[5],
                              1'b0, neg[4],
                              1'b0, neg[3],
                              1'b0, neg[2],
                              1'b0, neg[1],
                              1'b0, neg[0] };

    // ---- Финальное сложение ----
    assign p = row[0] + row[1] + row[2] + row[3]
             + row[4] + row[5] + row[6] + row[7]
             + neg_correction;

endmodule
