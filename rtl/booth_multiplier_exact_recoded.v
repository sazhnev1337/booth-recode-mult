module booth_multiplier_exact_recoded (
    input  wire signed [15:0] a,
    input  wire signed [15:0] b,
    output wire signed [31:0] p
);

    // Шаг 1: расширяем A снизу нулём, чтобы единообразно нарезать триплеты.
    // a_ext[2i+2:2i] = {a[2i+1], a[2i], a[2i-1]}, причём a[-1] = 0.
    wire [16:0] a_ext = {a, 1'b0};

    // Шаг 2: 4 кодировщика пар, каждый выдаёт две тройки.
    wire        neg [0:7];
    wire        one [0:7];
    wire        two [0:7];
    wire [16:0] pp  [0:7];

    genvar k;
    generate
        for (k = 0; k < 4; k = k + 1) begin : pair
            booth_recoder_pair_exact rec (
                .window (a_ext[4*k+4 : 4*k]),
                .neg_lo (neg[2*k]),
                .one_lo (one[2*k]),
                .two_lo (two[2*k]),
                .neg_hi (neg[2*k+1]),
                .one_hi (one[2*k+1]),
                .two_hi (two[2*k+1])
            );
        end
    endgenerate

    // Шаг 3: 8 PPG, идентично baseline.
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

    // Шаг 4: знаковое расширение и сдвиг, идентично baseline.
    wire signed [31:0] row [0:7];
    generate
        for (i = 0; i < 8; i = i + 1) begin : row_build
            assign row[i] = $signed(pp[i]) <<< (2*i);
        end
    endgenerate

    // Шаг 5: neg-коррекция, идентично baseline.
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

    // Шаг 6: сумма.
    assign p = row[0] + row[1] + row[2] + row[3]
             + row[4] + row[5] + row[6] + row[7]
             + neg_correction;

endmodule
