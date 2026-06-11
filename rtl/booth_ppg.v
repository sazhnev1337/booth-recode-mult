module booth_ppg (
    input  wire signed [15:0] b,
    input  wire               neg,
    input  wire               one,
    input  wire               two,
    output wire        [16:0] pp     // one's complement, если neg=1
);

    // Выбираем кратное B: 0, B или 2B (в 17 битах, signed-extended)
    wire [16:0] b_ext   = {b[15], b};        // 16 -> 17 бит, знаковое расширение
    wire [16:0] b_shift = {b, 1'b0};         // 2B в 17 битах

    wire [16:0] magnitude = two ? b_shift :
                            one ? b_ext   :
                                  17'b0;

    // Отрицание делаем как ~magnitude (one's complement).
    // Недостающую +1 будем подмешивать отдельно в дереве сложения.
    assign pp = neg ? ~magnitude : magnitude;

endmodule
