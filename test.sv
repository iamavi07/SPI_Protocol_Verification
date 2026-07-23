interface spi_if;

    logic        clk;
    logic        rst;
    logic        newd;

    logic [11:0] din;
    logic [11:0] dout;

    logic        done;
    logic        sclk;

endinterface


//======================================================
// Transaction Class
//======================================================

class transaction;

    bit          newd;
    rand bit [11:0] din;
    bit [11:0]   dout;

    function transaction copy();
        copy = new();

        copy.newd = this.newd;
        copy.din  = this.din;
        copy.dout = this.dout;
    endfunction

endclass



//======================================================
// Generator
//======================================================

class generator;

    transaction tr;

    mailbox #(transaction) mbx;

    event done;

    int count = 0;

    event drvnext;
    event sconext;

    function new(mailbox #(transaction) mbx);

        this.mbx = mbx;
        tr = new();

    endfunction


    task run();

        repeat(count)
        begin

            assert(tr.randomize())
            else
                $fatal("[GEN] Randomization Failed");

            mbx.put(tr.copy());

            $display("[GEN] : Generated Data = %0d (0x%03h)", tr.din, tr.din);

            @(sconext);

        end

        ->done;

    endtask

endclass




//======================================================
// Driver
//======================================================

class driver;

    virtual spi_if vif;

    transaction tr;

    mailbox #(transaction) mbx;

    mailbox #(bit [11:0]) mbxds;

    event drvnext;

    function new
    (
        mailbox #(bit [11:0]) mbxds,
        mailbox #(transaction) mbx
    );

        this.mbx   = mbx;
        this.mbxds = mbxds;

    endfunction



    //--------------------------------------------------
    // Reset Task
    //--------------------------------------------------

    task reset();

        vif.rst  <= 1'b1;
        vif.newd <= 1'b0;
        vif.din  <= '0;

        repeat(10)
            @(posedge vif.clk);

        vif.rst <= 1'b0;

        repeat(5)
            @(posedge vif.clk);

        $display("---------------------------------------------");
        $display("[DRV] Reset Completed");
        $display("---------------------------------------------");

    endtask



    //--------------------------------------------------
    // Driver Task
    //--------------------------------------------------

    task run();

        forever
        begin

            mbx.get(tr);

            //--------------------------------------------------
            // Apply transaction
            //--------------------------------------------------

            vif.din  <= tr.din;
            vif.newd <= 1'b1;

            mbxds.put(tr.din);

            @(posedge vif.clk);

            vif.newd <= 1'b0;

            //--------------------------------------------------
            // Wait for transfer completion
            //--------------------------------------------------

            @(posedge vif.done);

            $display("[DRV] : Sent Data = %0d (0x%03h)", tr.din, tr.din);

            @(posedge vif.sclk);

        end

    endtask

endclass
//======================================================
// Monitor
//======================================================

class monitor;

    transaction tr;

    mailbox #(bit [11:0]) mbx;

    virtual spi_if vif;

    function new(mailbox #(bit [11:0]) mbx);

        this.mbx = mbx;

    endfunction


    task run();

        tr = new();

        forever
        begin

            //--------------------------------------------------
            // Wait until transaction completes
            //--------------------------------------------------

            @(posedge vif.done);

            tr.dout = vif.dout;

            $display("[MON] : Received Data = %0d (0x%03h)",
                     tr.dout, tr.dout);

            mbx.put(tr.dout);

            @(posedge vif.sclk);

        end

    endtask

endclass




//======================================================
// Scoreboard
//======================================================

class scoreboard;

    mailbox #(bit [11:0]) mbxds;
    mailbox #(bit [11:0]) mbxms;

    bit [11:0] ds;
    bit [11:0] ms;

    event sconext;

    function new
    (
        mailbox #(bit [11:0]) mbxds,
        mailbox #(bit [11:0]) mbxms
    );

        this.mbxds = mbxds;
        this.mbxms = mbxms;

    endfunction


    task run();

        forever
        begin

            mbxds.get(ds);
            mbxms.get(ms);

            $display("[SCO] : Expected = %0d (0x%03h)",
                     ds, ds);

            $display("[SCO] : Received = %0d (0x%03h)",
                     ms, ms);

            if(ds === ms)
            begin
                $display("[SCO] : DATA MATCHED");
            end
            else
            begin
                $display("[SCO] : DATA MISMATCHED");
            end

            $display("---------------------------------------------");

            ->sconext;

        end

    endtask

endclass





//======================================================
// Environment
//======================================================

class environment;

    generator  gen;
    driver     drv;
    monitor    mon;
    scoreboard sco;

    event nextgd;
    event nextgs;

    mailbox #(transaction) mbxgd;

    mailbox #(bit [11:0]) mbxds;
    mailbox #(bit [11:0]) mbxms;

    virtual spi_if vif;


    function new(virtual spi_if vif);

        //--------------------------------------------------
        // Mailboxes
        //--------------------------------------------------

        mbxgd = new();
        mbxds = new();
        mbxms = new();

        //--------------------------------------------------
        // Components
        //--------------------------------------------------

        gen = new(mbxgd);
        drv = new(mbxds, mbxgd);
        mon = new(mbxms);
        sco = new(mbxds, mbxms);

        //--------------------------------------------------
        // Virtual Interface Connections
        //--------------------------------------------------

        this.vif = vif;

        drv.vif = this.vif;
        mon.vif = this.vif;

        //--------------------------------------------------
        // Event Connections
        //--------------------------------------------------

        gen.sconext = nextgs;
        sco.sconext = nextgs;

        gen.drvnext = nextgd;
        drv.drvnext = nextgd;

    endfunction



    //--------------------------------------------------
    // Reset Phase
    //--------------------------------------------------

    task pre_test();

        drv.reset();

    endtask



    //--------------------------------------------------
    // Test Phase
    //--------------------------------------------------

    task test();

        fork

            gen.run();

            drv.run();

            mon.run();

            sco.run();

        join_any

    endtask



    //--------------------------------------------------
    // Finish Phase
    //--------------------------------------------------

    task post_test();

        wait(gen.done.triggered);

        $display("---------------------------------------------");
        $display("SPI VERIFICATION COMPLETED");
        $display("---------------------------------------------");

        $finish();

    endtask



    //--------------------------------------------------
    // Run Environment
    //--------------------------------------------------

    task run();

        pre_test();

        test();

        post_test();

    endtask

endclass
//======================================================
// Top-Level Testbench
//======================================================

module tb;

    //--------------------------------------------------
    // Interface Instance
    //--------------------------------------------------

    spi_if vif();


    //--------------------------------------------------
    // DUT
    //--------------------------------------------------

    spi_top dut (

        .clk  (vif.clk),
        .rst  (vif.rst),
        .newd (vif.newd),
        .din  (vif.din),

        .sclk (vif.sclk),
        .cs   (),
        .mosi (),

        .done (vif.done),
        .dout (vif.dout)

    );


    //--------------------------------------------------
    // Clock Generation
    //--------------------------------------------------

    initial
        vif.clk = 1'b0;

    always #10 vif.clk = ~vif.clk;


    //--------------------------------------------------
    // Environment
    //--------------------------------------------------

    environment env;


    //--------------------------------------------------
    // Test
    //--------------------------------------------------

    initial begin

        env = new(vif);

        // Number of randomized SPI transactions
        env.gen.count = 4;

        env.run();

    end


    //--------------------------------------------------
    // Waveform Dump
    //--------------------------------------------------

    initial begin

        $dumpfile("spi_verification.vcd");
        $dumpvars(0, tb);

    end

endmodule
