`timescale 1ns/1ps

module tb_mult_booth;

    reg               clk;
    reg               rst_n;
    reg signed [15:0] a, b;
    wire signed [31:0] p;

    mult_booth dut (
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
    integer n_samples;
    integer a_val, b_val, recoded_val;
    reg [8*64-1:0] stimulus_path;

    initial begin
        $dumpfile("waves/power.vcd");
        $dumpvars(0, tb_mult_booth);

        rst_n = 0;
        a = 16'sd0;
        b = 16'sd0;
        #20;
        rst_n = 1;

        if (!$value$plusargs("STIM=%s", stimulus_path)) begin
            stimulus_path = "data/stim_uniform_fast_standard.txt";
        end
        if (!$value$plusargs("N=%d", n_samples)) begin
            n_samples = 10000;
        end

        fd = $fopen(stimulus_path, "r");
        if (fd == 0) begin
            $display("ERROR: cannot open %0s", stimulus_path);
            $finish;
        end

        $display("Reading stimulus from: %0s (N=%0d)", stimulus_path, n_samples);

        for (i = 0; i < n_samples; i = i + 1) begin
            code = $fscanf(fd, "%d\n%d\n%d\n", a_val, b_val, recoded_val);
            if (code != 3) begin
                $display("ERROR: stimulus file ended early at i=%0d", i);
                $finish;
            end
            @(negedge clk);
            a = a_val[15:0];
            b = b_val[15:0];
            // recoded_val игнорируется.
        end

        $fclose(fd);

        repeat (5) @(posedge clk);

        $display("Simulation done.");
        $finish;
    end

endmodule
