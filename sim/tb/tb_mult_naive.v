`timescale 1ns/1ps

module tb_mult_naive;

    reg               clk;
    reg               rst_n;
    reg signed [15:0] a, b;
    wire signed [31:0] p;

    mult_naive dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .p(p)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer fd;
    integer code;
    integer i;
    integer a_val, b_val, recoded_val;
    reg [8*64-1:0] stimulus_path;

    initial begin
        $dumpfile("waves/power.vcd");
        $dumpvars(0, tb_mult_naive);

        rst_n = 0;
        a = 16'sd0;
        b = 16'sd0;
        #20;
        rst_n = 1;

        if (!$value$plusargs("STIM=%s", stimulus_path)) begin
            stimulus_path = "data/stim_uniform_fast_standard.txt";
        end

        fd = $fopen(stimulus_path, "r");
        if (fd == 0) begin
            $display("ERROR: cannot open %0s", stimulus_path);
            $finish;
        end

        $display("Reading stimulus from: %0s", stimulus_path);

        for (i = 0; i < 10000; i = i + 1) begin
            code = $fscanf(fd, "%d\n%d\n%d\n", a_val, b_val, recoded_val);
            if (code != 3) begin
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
