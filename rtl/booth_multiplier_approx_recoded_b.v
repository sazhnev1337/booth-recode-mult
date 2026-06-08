module booth_multiplier_approx_recoded_b #(
    parameter APPROX_PAIRS = 1
) (
    input  wire signed [15:0] a,
    input  wire signed [15:0] b,
    output wire signed [31:0] p
);

    wire [16:0] a_ext = {a, 1'b0};

    // ---- 4 чётные пары ----
    // Младшие APPROX_PAIRS пар — approx, остальные — exact.
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
            if (k < APPROX_PAIRS) begin : approx_even
                booth_recoder_pair_approx_b rec_e (
                    .window           (a_ext[4*k+4 : 4*k]),
                    .neg_lo           (neg_even_lo[k]),
                    .one_lo           (one_even_lo[k]),
                    .two_lo           (two_even_lo[k]),
                    .neg_hi           (neg_even_hi[k]),
                    .one_hi           (one_even_hi[k]),
                    .two_hi           (two_even_hi[k]),
                    .pattern_detected (pd_even[k])
                );
            end else begin : exact_even
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
        end
    endgenerate

    // ---- enable для нечётных пар ----
    wire enable_odd [0:2];
    assign enable_odd[0] = ~pd_even[0] & ~pd_even[1];
    assign enable_odd[1] = ~pd_even[1] & ~pd_even[2];
    assign enable_odd[2] = ~pd_even[2] & ~pd_even[3];

    // ---- 3 нечётные пары ----
    // Нечётная пара l покрывает позиции (2l+1, 2l+2). Подбор exact/approx по позициям.
    // Чтобы не усложнять: если хотя бы одна из двух позиций пары — approx-зона,
    // используем approx-нечётную. Approx-зона = позиции 0..2*APPROX_PAIRS-1.
    // Нечётная l покрывает (2l+1, 2l+2). Approx если 2l+1 < 2*APPROX_PAIRS,
    // т.е. l < APPROX_PAIRS. При l == APPROX_PAIRS старшая позиция 2l+2 может быть exact,
    // а младшая 2l+1 — на границе; в этом случае выбираем approx, чтобы не потерять
    // нижнюю позицию.
    wire neg_odd_lo [0:2];
    wire one_odd_lo [0:2];
    wire two_odd_lo [0:2];
    wire neg_odd_hi [0:2];
    wire one_odd_hi [0:2];
    wire two_odd_hi [0:2];
    wire pd_odd     [0:2];

    genvar lg;
    generate
        for (lg = 0; lg < 3; lg = lg + 1) begin : odd_pair
            if (lg + 1 < APPROX_PAIRS) begin : approx_odd
		    booth_recoder_pair_odd_approx rec_o (
                    .window           (a_ext[4*lg+6 : 4*lg+2]),
                    .enable           (enable_odd[lg]),
                    .neg_lo           (neg_odd_lo[lg]),
                    .one_lo           (one_odd_lo[lg]),
                    .two_lo           (two_odd_lo[lg]),
                    .neg_hi           (neg_odd_hi[lg]),
                    .one_hi           (one_odd_hi[lg]),
                    .two_hi           (two_odd_hi[lg]),
                    .pattern_detected (pd_odd[lg])
                );
            end else begin : exact_odd
                booth_recoder_pair_odd_exact rec_o (
                    .window           (a_ext[4*lg+6 : 4*lg+2]),
                    .enable           (enable_odd[lg]),
                    .neg_lo           (neg_odd_lo[lg]),
                    .one_lo           (one_odd_lo[lg]),
                    .two_lo           (two_odd_lo[lg]),
                    .neg_hi           (neg_odd_hi[lg]),
                    .one_hi           (one_odd_hi[lg]),
                    .two_hi           (two_odd_hi[lg]),
                    .pattern_detected (pd_odd[lg])
                );
            end
        end
    endgenerate

    // ---- Per-позиция выбор источника ----
    wire        neg [0:7];
    wire        one [0:7];
    wire        two [0:7];

    assign neg[0] = neg_even_lo[0];
    assign one[0] = one_even_lo[0];
    assign two[0] = two_even_lo[0];

    assign neg[1] = pd_odd[0] ? neg_odd_lo[0] : neg_even_hi[0];
    assign one[1] = pd_odd[0] ? one_odd_lo[0] : one_even_hi[0];
    assign two[1] = pd_odd[0] ? two_odd_lo[0] : two_even_hi[0];

    assign neg[2] = pd_odd[0] ? neg_odd_hi[0] : neg_even_lo[1];
    assign one[2] = pd_odd[0] ? one_odd_hi[0] : one_even_lo[1];
    assign two[2] = pd_odd[0] ? two_odd_hi[0] : two_even_lo[1];

    assign neg[3] = pd_odd[1] ? neg_odd_lo[1] : neg_even_hi[1];
    assign one[3] = pd_odd[1] ? one_odd_lo[1] : one_even_hi[1];
    assign two[3] = pd_odd[1] ? two_odd_lo[1] : two_even_hi[1];

    assign neg[4] = pd_odd[1] ? neg_odd_hi[1] : neg_even_lo[2];
    assign one[4] = pd_odd[1] ? one_odd_hi[1] : one_even_lo[2];
    assign two[4] = pd_odd[1] ? two_odd_hi[1] : two_even_lo[2];

    assign neg[5] = pd_odd[2] ? neg_odd_lo[2] : neg_even_hi[2];
    assign one[5] = pd_odd[2] ? one_odd_lo[2] : one_even_hi[2];
    assign two[5] = pd_odd[2] ? two_odd_lo[2] : two_even_hi[2];

    assign neg[6] = pd_odd[2] ? neg_odd_hi[2] : neg_even_lo[3];
    assign one[6] = pd_odd[2] ? one_odd_hi[2] : one_even_lo[3];
    assign two[6] = pd_odd[2] ? two_odd_hi[2] : two_even_lo[3];

    assign neg[7] = neg_even_hi[3];
    assign one[7] = one_even_hi[3];
    assign two[7] = two_even_hi[3];

    // ---- 8 PPG ----
    wire [16:0] pp [0:7];
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ppg_lane
            booth_ppg ppg (
                .b   (b),
                .one (one[i]),
                .two (two[i]),
                .neg (neg[i]),
                .pp  (pp[i])
            );
        end
    endgenerate

    wire signed [31:0] row [0:7];
    generate
        for (i = 0; i < 8; i = i + 1) begin : row_build
            assign row[i] = $signed(pp[i]) <<< (2*i);
        end
    endgenerate

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

    assign p = row[0] + row[1] + row[2] + row[3]
             + row[4] + row[5] + row[6] + row[7]
             + neg_correction;

endmodule
