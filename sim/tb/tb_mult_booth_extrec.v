`timescale 1ns/1ps

module tb_mult_booth_extrec;

    reg               clk;
    reg               rst_n;
    reg        [23:0] a_recoded;
    reg signed [15:0] b;
    wire signed [31:0] p;

    mult_booth_extrec dut (
        .clk(clk),
        .rst_n(rst_n),
        .a_recoded(a_recoded),
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
        $dumpvars(0, tb_mult_booth_extrec);

        rst_n = 0;
        a_recoded = 24'b0;
        b = 16'sd0;
        #20;
        rst_n = 1;

        if (!$value$plusargs("STIM=%s", stimulus_path)) begin
            stimulus_path = "data/stim_uniform_fast_exact.txt";
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
            // a_val игнорируется — этот тестбенч работает с recoded-данными.
            b = b_val[15:0];
            a_recoded = recoded_val[23:0];
        end

        $fclose(fd);

        repeat (5) @(posedge clk);

        $display("Simulation done.");
        $finish;
    end

endmodule
