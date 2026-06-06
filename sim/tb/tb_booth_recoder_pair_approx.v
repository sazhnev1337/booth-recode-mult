`timescale 1ns/1ps

module tb_booth_recoder_pair_approx;

    reg  [4:0] window;
    wire       neg_lo, one_lo, two_lo;
    wire       neg_hi, one_hi, two_hi;

    booth_recoder_pair_approx dut (
        .window (window),
        .neg_lo (neg_lo), .one_lo (one_lo), .two_lo (two_lo),
        .neg_hi (neg_hi), .one_hi (one_hi), .two_hi (two_hi)
    );

    function signed [3:0] decode;
        input neg, one, two;
        begin
            if (two)
                decode = neg ? -4'sd2 : 4'sd2;
            else if (one)
                decode = neg ? -4'sd1 : 4'sd1;
            else
                decode = 4'sd0;
        end
    endfunction

    integer i;
    integer errors;

    reg signed [3:0] m_lo_ref, m_hi_ref;
    reg signed [7:0] ref_contribution, dut_contribution;
    reg signed [7:0] error_actual, error_expected;
    reg              a_m1, a_0, a_1, a_2, a_3;

    initial begin
        errors = 0;
        $display("window | dut | ref | err | expected");
        $display("-------+-----+-----+-----+---------");

        for (i = 0; i < 32; i = i + 1) begin
            window = i[4:0];
            #1;

            a_m1 = window[0];
            a_0  = window[1];
            a_1  = window[2];
            a_2  = window[3];
            a_3  = window[4];

            m_lo_ref = -2*a_1 + a_0 + a_m1;
            m_hi_ref = -2*a_3 + a_2 + a_1;
            ref_contribution = m_hi_ref * 4 + m_lo_ref;

            dut_contribution =   decode(neg_hi, one_hi, two_hi) * 4
                               + decode(neg_lo, one_lo, two_lo);

            error_actual = dut_contribution - ref_contribution;

            // Ожидаемая ошибка по таблице approx-паттернов.
            case (window)
                5'b00101, 5'b00110: error_expected = -8'sd1;
                5'b11010, 5'b11001: error_expected =  8'sd1;
                default:            error_expected =  8'sd0;
            endcase

            $display(" %b | %3d | %3d | %3d | %3d",
                     window, dut_contribution, ref_contribution,
                     error_actual, error_expected);

            if (error_actual !== error_expected) begin
                $display("  ^ MISMATCH");
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("PASS: all 32 windows OK (exact + approx behaviour correct)");
        else
            $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule