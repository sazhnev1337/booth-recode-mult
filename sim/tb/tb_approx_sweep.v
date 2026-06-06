`timescale 1ns/1ps

module tb_approx_sweep;

    localparam integer N_TESTS = 10000;

    reg  signed [15:0] a, b;
    wire signed [31:0] p_exact;
    wire signed [31:0] p_a1, p_a2, p_a3, p_a4;
    wire signed [31:0] p_ref;

    // Эталон — встроенное знаковое умножение симулятора.
    assign p_ref = a * b;

    // Pure exact recoded (APPROX_PAIRS=0 эквивалентно booth_multiplier_exact_recoded).
    booth_multiplier_approx_recoded #(.APPROX_PAIRS(0)) dut_exact (
        .a(a), .b(b), .p(p_exact)
    );

    booth_multiplier_approx_recoded #(.APPROX_PAIRS(1)) dut_a1 (
        .a(a), .b(b), .p(p_a1)
    );

    booth_multiplier_approx_recoded #(.APPROX_PAIRS(2)) dut_a2 (
        .a(a), .b(b), .p(p_a2)
    );

    booth_multiplier_approx_recoded #(.APPROX_PAIRS(3)) dut_a3 (
        .a(a), .b(b), .p(p_a3)
    );

    booth_multiplier_approx_recoded #(.APPROX_PAIRS(4)) dut_a4 (
        .a(a), .b(b), .p(p_a4)
    );

    integer fd_exact, fd_a1, fd_a2, fd_a3, fd_a4;
    integer i;
    integer seed;

    initial begin
        seed = 32'hDEADBEEF;

        fd_exact = $fopen("./data/exact.csv",    "w");
        fd_a1    = $fopen("./data/approx_1.csv", "w");
        fd_a2    = $fopen("./data/approx_2.csv", "w");
        fd_a3    = $fopen("./data/approx_3.csv", "w");
        fd_a4    = $fopen("./data/approx_4.csv", "w");

        if (fd_exact == 0 || fd_a1 == 0 || fd_a2 == 0 || fd_a3 == 0 || fd_a4 == 0) begin
            $display("ERROR: could not open output file.");
            $finish;
        end

        for (i = 0; i < N_TESTS; i = i + 1) begin
            a = $random(seed);
            b = $random(seed);
            #1;

            $fwrite(fd_exact, "%0d,%0d,%0d,%0d\n", a, b, p_exact, p_ref);
            $fwrite(fd_a1,    "%0d,%0d,%0d,%0d\n", a, b, p_a1,    p_ref);
            $fwrite(fd_a2,    "%0d,%0d,%0d,%0d\n", a, b, p_a2,    p_ref);
            $fwrite(fd_a3,    "%0d,%0d,%0d,%0d\n", a, b, p_a3,    p_ref);
            $fwrite(fd_a4,    "%0d,%0d,%0d,%0d\n", a, b, p_a4,    p_ref);
        end

        $fclose(fd_exact);
        $fclose(fd_a1);
        $fclose(fd_a2);
        $fclose(fd_a3);
        $fclose(fd_a4);

        $display("Done: %0d tests written to ./data/", N_TESTS);
        $finish;
    end

endmodule