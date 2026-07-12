module spi_master(
    input  logic        clk,
    input  logic        rst,
    input  logic        newd,
    input  logic [11:0] din,

    output logic        sclk,
    output logic        cs,
    output logic        mosi,
    output logic        done
);

    logic [11:0] shift_reg;
    logic [3:0]  bit_cnt;
    logic [2:0]  clk_div;
    logic        busy;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk      <= 1'b0;
            cs        <= 1'b1;
            mosi      <= 1'b0;
            done      <= 1'b0;
            busy      <= 1'b0;
            bit_cnt   <= 4'd0;
            clk_div   <= 3'd0;
            shift_reg <= 12'd0;
        end
        else begin
            done <= 1'b0;

            if (!busy && newd) begin
                busy      <= 1'b1;
                cs        <= 1'b0;
                sclk      <= 1'b0;
                clk_div   <= 3'd0;
                bit_cnt   <= 4'd12;
                shift_reg <= din;
                mosi      <= din[11];
            end

            else if (busy) begin

                clk_div <= clk_div + 1'b1;

                // Divide system clock by 4
                if (clk_div == 3) begin
                    clk_div <= 0;
                    sclk <= ~sclk;

                    // Falling edge:
                    // shift next bit out
                    if (sclk) begin
                        shift_reg <= {shift_reg[10:0],1'b0};

                        if (bit_cnt > 1)
                            mosi <= shift_reg[10];
                    end

                    // Rising edge:
                    // count transmitted bits
                    else begin
                        bit_cnt <= bit_cnt - 1'b1;

                        if (bit_cnt == 1) begin
                            busy <= 1'b0;
                            done <= 1'b1;
                        end

                        if (!busy && done) begin
                            cs   <= 1;
                            sclk <= 0;
                        end
                    end
                end
            end
        end
    end

endmodule