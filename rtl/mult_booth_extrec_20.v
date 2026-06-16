// 20x20 Booth multiplier with external recoder (10 PPG lanes, 40-bit output).
// a_recoded = {two[9:0], one[9:0], neg[9:0]}  (30 bits)
module mult_booth_extrec_20 (
    input  wire               clk,
    input  wire               rst_n,
    input  wire        [29:0] a_recoded,
    input  wire signed [19:0] b,
    output reg  signed [39:0] p
);
    reg        [29:0] a_recoded_q;
    reg signed [19:0] b_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_recoded_q <= 30'b0;
            b_q         <= 20'sd0;
        end else begin
            a_recoded_q <= a_recoded;
            b_q         <= b;
        end
    end

    wire [9:0] neg_bits = a_recoded_q[9:0];
    wire [9:0] one_bits = a_recoded_q[19:10];
    wire [9:0] two_bits = a_recoded_q[29:20];

    wire [20:0] pp [0:9];
    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : ppg_lane
            booth_ppg_20 ppg (
                .b   (b_q),
                .neg (neg_bits[i]),
                .one (one_bits[i]),
                .two (two_bits[i]),
                .pp  (pp[i])
            );
        end
    endgenerate

    wire signed [39:0] row [0:9];
    generate
        for (i = 0; i < 10; i = i + 1) begin : row_build
            assign row[i] = $signed(pp[i]) <<< (2*i);
        end
    endgenerate

    wire signed [39:0] neg_correction;
    assign neg_correction = { 20'b0,
                              1'b0, neg_bits[9],
                              1'b0, neg_bits[8],
                              1'b0, neg_bits[7],
                              1'b0, neg_bits[6],
                              1'b0, neg_bits[5],
                              1'b0, neg_bits[4],
                              1'b0, neg_bits[3],
                              1'b0, neg_bits[2],
                              1'b0, neg_bits[1],
                              1'b0, neg_bits[0] };

    wire signed [39:0] p_comb = row[0] + row[1] + row[2] + row[3] + row[4] +
                                row[5] + row[6] + row[7] + row[8] + row[9] +
                                neg_correction;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) p <= 40'sd0;
        else        p <= p_comb;
    end
endmodule
