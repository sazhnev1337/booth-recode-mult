`timescale 1ns/1ps

module tb_power;

    reg [8*64-1:0] stimulus_path;
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
        $dumpfile("waves/power.vcd");
        $dumpvars(0, tb_power);

        // Reset.
        rst_n = 0;
        a = 0;
        b = 0;
        #20;
        rst_n = 1;

        // Получаем путь к файлу стимулов из +STIM=...
        // Дефолт сохраняет обратную совместимость.
        if (!$value$plusargs("STIM=%s", stimulus_path)) begin
            stimulus_path = "data/stimulus_uniform_fast.txt";
        end

        // Открываем файл стимулов.
        fd = $fopen(stimulus_path, "r");
        if (fd == 0) begin
            $display("ERROR: cannot open %0s", stimulus_path);
            $finish;
        end

        $display("Reading stimulus from: %0s", stimulus_path);

        // Подаём векторы — по одной паре за такт.
        for (i = 0; i < 10000; i = i + 1) begin
            code = $fscanf(fd, "%d\n%d\n", a_val, b_val);
            if (code != 2) begin
                $display("ERROR: stimulus file ended early at i=%0d", i);
                $finish;
            end
            @(negedge clk);
            a = a_val[15:0];
            b = b_val[15:0];
        end

        $fclose(fd);

        repeat (5) @(posedge clk);

        $display("Simulation done.");
        $finish;
    end
endmodule
