// 8x8 Booth multiplier with external recoder (4 PPG lanes, 16-bit output).
// a_recoded = {two[3:0], one[3:0], neg[3:0]}  (12 bits)
module mult_booth_extrec_8 (
    input  wire               clk,
    input  wire               rst_n,
    input  wire        [11:0] a_recoded,
    input  wire signed [7:0]  b,
    output reg  signed [15:0] p
);
    reg        [11:0] a_recoded_q;
    reg signed [7:0]  b_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_recoded_q <= 12'b0;
            b_q         <= 8'sd0;
        end else begin
            a_recoded_q <= a_recoded;
            b_q         <= b;
        end
    end

    wire [3:0] neg_bits = a_recoded_q[3:0];
    wire [3:0] one_bits = a_recoded_q[7:4];
    wire [3:0] two_bits = a_recoded_q[11:8];

    wire [8:0] pp [0:3];
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : ppg_lane
            booth_ppg_8 ppg (
                .b   (b_q),
                .neg (neg_bits[i]),
                .one (one_bits[i]),
                .two (two_bits[i]),
                .pp  (pp[i])
            );
        end
    endgenerate

    wire signed [15:0] row [0:3];
    generate
        for (i = 0; i < 4; i = i + 1) begin : row_build
            assign row[i] = $signed(pp[i]) <<< (2*i);
        end
    endgenerate

    wire signed [15:0] neg_correction;
    assign neg_correction = { 8'b0,
                              1'b0, neg_bits[3],
                              1'b0, neg_bits[2],
                              1'b0, neg_bits[1],
                              1'b0, neg_bits[0] };

    wire signed [15:0] p_comb = row[0] + row[1] + row[2] + row[3] + neg_correction;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) p <= 16'sd0;
        else        p <= p_comb;
    end
endmodule
