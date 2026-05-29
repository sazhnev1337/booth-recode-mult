module booth_multiplier (
    input  wire signed [15:0] a,
    input  wire signed [15:0] b,
    output wire signed [31:0] p
);

    // Шаг 1: расширяем A снизу нулём, чтобы единообразно нарезать триплеты.
    // a_ext[2i+2:2i] = {a[2i+1], a[2i], a[2i-1]}, причём a[-1] = 0.
    wire [16:0] a_ext = {a, 1'b0};

    // Шаг 2: восемь параллельных кодировщиков + PPG.
    wire        neg [0:7];
    wire        one [0:7];
    wire        two [0:7];
    wire [16:0] pp  [0:7];

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : booth_lane
            booth_encoder enc (
                .triplet (a_ext[2*i+2 : 2*i]),
                .neg     (neg[i]),
                .one     (one[i]),
                .two     (two[i])
            );

            booth_ppg ppg (
                .b   (b),
                .neg (neg[i]),
                .one (one[i]),
                .two (two[i]),
                .pp  (pp[i])
            );
        end
    endgenerate

    // Шаг 3: знаковое расширение каждой строки до 32 бит и сдвиг на 2i.
    // Расширяем по старшему биту pp_i (он играет роль знака one's complement).
    wire signed [31:0] row [0:7];
    generate
        for (i = 0; i < 8; i = i + 1) begin : row_build
            assign row[i] = $signed(pp[i]) <<< (2*i);
        end
    endgenerate

    // Шаг 4: коррекция за one's complement. Каждый neg_i даёт +1 в позицию 2i.
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

    // Шаг 5: суммируем всё. Yosys развернёт это в дерево сумматоров.
    assign p = row[0] + row[1] + row[2] + row[3]
             + row[4] + row[5] + row[6] + row[7]
             + neg_correction;

endmodule