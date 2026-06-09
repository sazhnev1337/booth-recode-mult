module mult_booth_extrec (
    input  wire               clk,
    input  wire               rst_n,
    input  wire        [23:0] a_recoded,   // {two[7:0], one[7:0], neg[7:0]} от внешнего recoder
    input  wire signed [15:0] b,
    output reg  signed [31:0] p
);

    // ---- Входные регистры ----
    reg        [23:0] a_recoded_q;
    reg signed [15:0] b_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_recoded_q <= 24'b0;
            b_q         <= 16'sd0;
        end else begin
            a_recoded_q <= a_recoded;
            b_q         <= b;
        end
    end

    // ---- Распаковка recoded-вектора на per-position сигналы ----
    // Раскладка по соглашению из Python:
    //   bits [7:0]   = neg[7:0]
    //   bits [15:8]  = one[7:0]
    //   bits [23:16] = two[7:0]
    wire [7:0] neg_bits = a_recoded_q[7:0];
    wire [7:0] one_bits = a_recoded_q[15:8];
    wire [7:0] two_bits = a_recoded_q[23:16];

    // ---- 8 PPG ----
    wire [16:0] pp [0:7];
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ppg_lane
            booth_ppg ppg (
                .b   (b_q),
                .neg (neg_bits[i]),
                .one (one_bits[i]),
                .two (two_bits[i]),
                .pp  (pp[i])
            );
        end
    endgenerate

    // ---- Знаковое расширение и сдвиг ----
    wire signed [31:0] row [0:7];
    generate
        for (i = 0; i < 8; i = i + 1) begin : row_build
            assign row[i] = $signed(pp[i]) <<< (2*i);
        end
    endgenerate

    // ---- Neg-коррекция (обычная, как в baseline) ----
    wire signed [31:0] neg_correction;
    assign neg_correction = { 16'b0,
                              1'b0, neg_bits[7],
                              1'b0, neg_bits[6],
                              1'b0, neg_bits[5],
                              1'b0, neg_bits[4],
                              1'b0, neg_bits[3],
                              1'b0, neg_bits[2],
                              1'b0, neg_bits[1],
                              1'b0, neg_bits[0] };

    // ---- Финальное сложение + выходной регистр ----
    wire signed [31:0] p_comb;
    assign p_comb = row[0] + row[1] + row[2] + row[3]
                  + row[4] + row[5] + row[6] + row[7]
                  + neg_correction;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            p <= 32'sd0;
        else
            p <= p_comb;
    end

endmodule
