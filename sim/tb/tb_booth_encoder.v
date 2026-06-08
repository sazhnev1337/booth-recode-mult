`timescale 1ns/1ps

module tb_booth_encoder;

    reg  [2:0] triplet;
    wire       neg, one, two;

    booth_encoder dut (
        .triplet(triplet),
        .neg(neg),
        .one(one),
        .two(two)
    );

    integer i;

    initial begin
        $display("triplet | neg one two");
        $display("--------+------------");
        for (i = 0; i < 8; i = i + 1) begin
            triplet = i[2:0];
            #1;
            $display("  %b   |  %b   %b   %b", triplet, neg, one, two);
        end
        $finish;
    end

endmodule
