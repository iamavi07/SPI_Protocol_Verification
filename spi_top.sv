module spi_top(

    input  logic        clk,
    input  logic        rst,
    input  logic        newd,
    input  logic [11:0] din,

    output logic        sclk,
    output logic        cs,
    output logic        mosi,
    output logic        done,
    output logic [11:0] dout

);

    spi_master master_inst (
        .clk(clk),
        .rst(rst),
        .newd(newd),
        .din(din),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .done(done)
    );

    spi_slave slave_inst (
        .rst(rst),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .dout(dout)
    );

endmodule
