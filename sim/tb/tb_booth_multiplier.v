`timescale 1ns/1ps

module tb_booth_multiplier;

    reg  signed [15:0] a, b;
    wire signed [31:0] p;
    wire signed [31:0] p_ref;

    booth_multiplier dut (
        .a(a),
        .b(b),
        .p(p)
    );

    assign p_ref = a * b;

    integer i;
    integer errors;

    // Корнер-кейсы: нули, единицы, экстремумы знаковых границ.
    reg signed [15:0] corners [0:7];
    initial begin
        corners[0] = 16'sd0;
        corners[1] = 16'sd1;
        corners[2] = -16'sd1;
        corners[3] = 16'sh7FFF;   //  32767
        corners[4] = -16'sd32768; // -32768
        corners[5] = 16'sh5555;
        corners[6] = 16'shAAAA;
        corners[7] = 16'shFFFF;   // -1, ещё одна проверка
    end

    integer ci, cj;

    initial begin
        errors = 0;

        // 1) Все пары из corner-значений (8x8 = 64 теста).
        for (ci = 0; ci < 8; ci = ci + 1) begin
            for (cj = 0; cj < 8; cj = cj + 1) begin
                a = corners[ci];
                b = corners[cj];
                #1;
                if (p !== p_ref) begin
                    $display("CORNER FAIL: a=%0d b=%0d  got=%0d  ref=%0d",
                             a, b, p, p_ref);
                    errors = errors + 1;
                end
            end
        end

        // 2) Случайная выборка.
        for (i = 0; i < 10000; i = i + 1) begin
            a = $random;
            b = $random;
            #1;
            if (p !== p_ref) begin
                $display("RAND FAIL: a=%0d b=%0d  got=%0d  ref=%0d",
                         a, b, p, p_ref);
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("PASS: all tests OK");
        else
            $display("FAIL: %0d errors", errors);

        $finish;
    end

endmodule
