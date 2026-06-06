`timescale 1ns/1ps

module tb_power;

    reg               clk;
    reg               rst_n;
    reg  signed [15:0] a, b;
    wire signed [31:0] p;

    booth_multiplier_wrapper dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .p(p)
    );

    // Тактирование: 100 МГц = период 10 нс.
    initial clk = 0;
    always #5 clk = ~clk;

    integer fd;
    integer code;
    integer i;
    integer a_val, b_val;

    initial begin
        // VCD setup: дампим всё внутри wrapper'а.
        $dumpfile("power.vcd");
        $dumpvars(0, tb_power);

        // Reset.
        rst_n = 0;
        a = 0;
        b = 0;
        #20;
        rst_n = 1;

        // Открываем файл стимулов.
        fd = $fopen("data/stimulus.txt", "r");
        if (fd == 0) begin
            $display("ERROR: cannot open data/stimulus.txt");
            $finish;
        end

        // Подаём векторы — по одной паре за такт.
        for (i = 0; i < 10000; i = i + 1) begin
            code = $fscanf(fd, "%d\n%d\n", a_val, b_val);
            if (code != 2) begin
                $display("ERROR: stimulus file ended early at i=%0d", i);
                $finish;
            end
            @(negedge clk);  // меняем входы по спаду — за половину такта до posedge
            a = a_val[15:0];
            b = b_val[15:0];
        end

        $fclose(fd);

        // Подождём несколько тактов, чтобы pipeline дочистился.
        repeat (5) @(posedge clk);

        $display("Simulation done.");
        $finish;
    end

endmodule
