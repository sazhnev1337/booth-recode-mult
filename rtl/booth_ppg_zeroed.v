module booth_ppg_zeroed (
    input  wire signed [15:0] b,
    input  wire               neg,
    input  wire               one,
    input  wire               two,
    output wire        [16:0] pp     // one's complement, если neg=1 И строка ненулевая
);

    // Выбираем кратное B: 0, B или 2B (в 17 битах).
    wire [16:0] b_ext   = {b[15], b};
    wire [16:0] b_shift = {b, 1'b0};

    wire is_nonzero = one | two;

    // Маскируем magnitude до инверсии: если строка нулевая, magnitude гарантированно 0.
    wire [16:0] magnitude_masked = two        ? b_shift :
                                   one        ? b_ext   :
                                                17'b0;

    // Инвертируем только при neg=1 И строка ненулевая.
    // Если is_nonzero=0, magnitude_masked = 0, и независимо от neg выход остаётся 0
    // (потому что neg_effective ниже тоже занулится в neg_correction).
    wire neg_effective = neg & is_nonzero;

    assign pp = neg_effective ? ~magnitude_masked : magnitude_masked;

endmodule
