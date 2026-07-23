`timescale 1ns/1ps

module simple_tb;

    //--------------------------------------------------
    // Testbench Signals
    //--------------------------------------------------

    logic        clk;
    logic        rst;
    logic        newd;
    logic [11:0] din;

    logic        sclk;
    logic        cs;
    logic        mosi;
    logic        done;
    logic [11:0] dout;

    integer i;

    //--------------------------------------------------
    // DUT Instantiation
    //--------------------------------------------------

    spi_top dut (
        .clk  (clk),
        .rst  (rst),
        .newd (newd),
        .din  (din),

        .sclk (sclk),
        .cs   (cs),
        .mosi (mosi),
        .done (done),
        .dout (dout)
    );

    //--------------------------------------------------
    // Clock Generation (100 MHz)
    //--------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //--------------------------------------------------
    // Waveform Dump
    //--------------------------------------------------

    initial begin
        $dumpfile("spi.vcd");
        $dumpvars(0, simple_tb);
    end

    //--------------------------------------------------
    // Test Sequence
    //--------------------------------------------------

    initial begin

        //--------------------------------------------------
        // Initialize Signals
        //--------------------------------------------------

        rst  = 1'b1;
        newd = 1'b0;
        din  = '0;

        //--------------------------------------------------
        // Apply Reset
        //--------------------------------------------------

        #20;
        rst = 1'b0;

        #20;

        //--------------------------------------------------
        // Generate Transactions
        //--------------------------------------------------

        for(i = 0; i < 10; i = i + 1)
        begin

            // Random 12-bit data
            din = $urandom_range(0, 12'hFFF);

            //--------------------------------------------------
            // Start SPI Transfer
            //--------------------------------------------------

            @(posedge clk);
            newd = 1'b1;

            @(posedge clk);
            newd = 1'b0;

            //--------------------------------------------------
            // Wait for Completion (with Timeout)
            //--------------------------------------------------

            fork
            begin
                @(posedge done);
            end
            begin
                #50000;
                $fatal("ERROR: SPI transaction timed out.");
            end
            join_any
            disable fork;

            //--------------------------------------------------
            // Display Results
            //--------------------------------------------------

            $display("\n--------------------------------------------");
            $display("Transaction : %0d", i + 1);
            $display("TX Data     : %03h (%0d)", din, din);
            $display("RX Data     : %03h (%0d)", dout, dout);

            if (din === dout)
                $display("STATUS      : PASS");
            else
                $display("STATUS      : FAIL");

            $display("--------------------------------------------");

            repeat(4) @(posedge clk);

        end

        //--------------------------------------------------
        // End of Simulation
        //--------------------------------------------------

        $display("\n============================================");
        $display("SPI VERIFICATION COMPLETED SUCCESSFULLY");
        $display("Total Transactions : %0d", i);
        $display("============================================\n");

        #20;
        $finish;

    end

endmodule
