module mult_booth (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [15:0] a,
    input  wire signed [15:0] b,
    output reg  signed [31:0] p
);

    reg signed [15:0] a_q, b_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_q <= 16'sd0;
            b_q <= 16'sd0;
        end else begin
            a_q <= a;
            b_q <= b;
        end
    end

    // R4 Booth: 8 кодировщиков, 8 PPG, дерево сложения.
    wire [16:0] a_ext = {a_q, 1'b0};

    wire        neg [0:7];
    wire        one [0:7];
    wire        two [0:7];
    wire [16:0] pp  [0:7];

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : lane
            booth_encoder enc (
                .triplet (a_ext[2*i+2 : 2*i]),
                .neg     (neg[i]),
                .one     (one[i]),
                .two     (two[i])
            );
            booth_ppg ppg (
                .b   (b_q),
                .neg (neg[i]),
                .one (one[i]),
                .two (two[i]),
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

    wire signed [31:0] p_comb = row[0] + row[1] + row[2] + row[3] +
                                row[4] + row[5] + row[6] + row[7] + neg_correction;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            p <= 32'sd0;
        else
            p <= p_comb;
    end

endmodule
