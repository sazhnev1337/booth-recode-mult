// 20x20 Radix-4 Booth multiplier (10 PPG lanes, 40-bit output).
module mult_booth_20 (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [19:0] a,
    input  wire signed [19:0] b,
    output reg  signed [39:0] p
);
    reg signed [19:0] a_q, b_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_q <= 20'sd0;
            b_q <= 20'sd0;
        end else begin
            a_q <= a;
            b_q <= b;
        end
    end

    wire [20:0] a_ext = {a_q, 1'b0};

    wire         neg [0:9];
    wire         one [0:9];
    wire         two [0:9];
    wire [20:0]  pp  [0:9];

    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : lane
            booth_encoder enc (
                .triplet (a_ext[2*i+2 : 2*i]),
                .neg     (neg[i]),
                .one     (one[i]),
                .two     (two[i])
            );
            booth_ppg_20 ppg (
                .b   (b_q),
                .neg (neg[i]),
                .one (one[i]),
                .two (two[i]),
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

    // neg[i] lands at bit position 2*i (one's-complement +1 correction).
    wire signed [39:0] neg_correction;
    assign neg_correction = { 20'b0,
                              1'b0, neg[9],
                              1'b0, neg[8],
                              1'b0, neg[7],
                              1'b0, neg[6],
                              1'b0, neg[5],
                              1'b0, neg[4],
                              1'b0, neg[3],
                              1'b0, neg[2],
                              1'b0, neg[1],
                              1'b0, neg[0] };

    wire signed [39:0] p_comb = row[0] + row[1] + row[2] + row[3] + row[4] +
                                row[5] + row[6] + row[7] + row[8] + row[9] +
                                neg_correction;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) p <= 40'sd0;
        else        p <= p_comb;
    end
endmodule
