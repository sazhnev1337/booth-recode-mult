module mult_naive (
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

    wire signed [31:0] p_comb = a_q * b_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            p <= 32'sd0;
        else
            p <= p_comb;
    end

endmodule
