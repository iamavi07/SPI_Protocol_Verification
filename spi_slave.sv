module spi_slave(
    input  logic        rst,
    input  logic        sclk,
    input  logic        cs,
    input  logic        mosi,

    output logic [11:0] dout
);

    logic [11:0] shift_reg;
    logic [3:0]  bit_cnt;

    always_ff @(posedge sclk or posedge rst or posedge cs) begin
        if (rst) begin
            shift_reg <= 0;
            dout      <= 0;
            bit_cnt   <= 0;
        end
        else if (cs) begin
            bit_cnt <= 0;
        end
        else begin
            shift_reg <= {shift_reg[10:0], mosi};

            if (bit_cnt == 11) begin
                dout    <= {shift_reg[10:0], mosi};
                bit_cnt <= 0;
            end
            else begin
                bit_cnt <= bit_cnt + 1;
            end
        end
    end

endmodule