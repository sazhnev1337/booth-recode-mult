module booth_multiplier_wrapper #(
    parameter integer DUT_TYPE        = 0,   // 0=BASELINE, 1=EXACT, 2=APPROX
    parameter integer APPROX_PAIRS    = 1,
    parameter integer USE_ZEROED_PPG  = 0,   // 0=обычный PPG, 1=zeroed (только для DUT_TYPE 1,2)
    parameter integer USE_LEVEL_B     = 0    // 0=level A, 1=level B (только для DUT_TYPE 1,2)
) (
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

    wire signed [31:0] p_comb;

    generate
        if (DUT_TYPE == 0) begin : g_baseline
            booth_multiplier dut (.a(a_q), .b(b_q), .p(p_comb));
        end else if (DUT_TYPE == 1) begin : g_exact
            if (USE_LEVEL_B == 1) begin : g_level_b
                booth_multiplier_exact_recoded_b dut (.a(a_q), .b(b_q), .p(p_comb));
            end else if (USE_ZEROED_PPG == 1) begin : g_zeroed
                booth_multiplier_exact_recoded_zeroed dut (.a(a_q), .b(b_q), .p(p_comb));
            end else begin : g_normal
                booth_multiplier_exact_recoded dut (.a(a_q), .b(b_q), .p(p_comb));
            end
        end else if (DUT_TYPE == 2) begin : g_approx
            if (USE_LEVEL_B == 1) begin : g_level_b
                booth_multiplier_approx_recoded_b #(.APPROX_PAIRS(APPROX_PAIRS)) dut (
                    .a(a_q), .b(b_q), .p(p_comb)
                );
            end else if (USE_ZEROED_PPG == 1) begin : g_zeroed
                booth_multiplier_approx_recoded_zeroed #(.APPROX_PAIRS(APPROX_PAIRS)) dut (
                    .a(a_q), .b(b_q), .p(p_comb)
                );
            end else begin : g_normal
                booth_multiplier_approx_recoded #(.APPROX_PAIRS(APPROX_PAIRS)) dut (
                    .a(a_q), .b(b_q), .p(p_comb)
                );
            end
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p <= 32'sd0;
        end else begin
            p <= p_comb;
        end
    end

endmodule
