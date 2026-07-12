`timescale 1ns/1ps

module simple_tb;

    logic clk;
    logic rst;
    logic newd;
    logic [11:0] din;

    logic sclk;
    logic cs;
    logic mosi;
    logic done;
    logic [11:0] dout;

    spi_top dut (
        .clk(clk),
        .rst(rst),
        .newd(newd),
        .din(din),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .done(done),
        .dout(dout)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("spi.vcd");
        $dumpvars(0, simple_tb);
    end

    integer i;

    initial begin

        rst  = 1;
        newd = 0;
        din  = 0;

        #20;
        rst = 0;

        #20;

        for(i = 0; i < 10; i = i + 1) begin

            din = $random & 12'hFFF;

            @(posedge clk);
            newd = 1;

            @(posedge clk);
            newd = 0;

            @(posedge done);

            $display("--------------------------------");
            $display("Transfer %0d Complete", i+1);
            $display("TX Data = %03h", din);
            $display("RX Data = %03h", dout);

            #40;

        end

        $display("--------------------------------");
        $display("Simulation Finished Successfully");
        $display("--------------------------------");

        #20;
        $finish;

    end

endmodule