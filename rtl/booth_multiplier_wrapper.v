module booth_multiplier_wrapper #(
    parameter DUT_TYPE     = 0, // 0=BASELINE", 1=EXACT, 2=APPROX
    parameter APPROX_PAIRS = 1            // используется только при DUT_TYPE = "APPROX"
) (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [15:0] a,
    input  wire signed [15:0] b,
    output reg  signed [31:0] p
);

    // Входные регистры.
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

    // Комбинационный DUT — выбор по параметру.
    wire signed [31:0] p_comb;

    generate
        if (DUT_TYPE == 0) begin : g_baseline
            booth_multiplier dut (
                .a(a_q), .b(b_q), .p(p_comb)
            );
        end else if (DUT_TYPE == 1) begin : g_exact
            booth_multiplier_exact_recoded dut (
                .a(a_q), .b(b_q), .p(p_comb)
            );
        end else if (DUT_TYPE == 2) begin : g_approx
            booth_multiplier_approx_recoded #(.APPROX_PAIRS(APPROX_PAIRS)) dut (
                .a(a_q), .b(b_q), .p(p_comb)
            );
        end
    endgenerate

    // Выходной регистр.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p <= 32'sd0;
        end else begin
            p <= p_comb;
        end
    end

endmodule