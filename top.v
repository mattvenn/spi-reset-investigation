`default_nettype none
module top (
    input  clk,
    output [7:0] pmod6,
    output spi_cipo,
    input spi_clk,
    input spi_copi,
    input spi_cs,
    input reset_async

);
    // power on and reset sync
    reg [5:0] reset_cnt = 0;
    wire reset = reset_cnt < (1<<5);

    always @(posedge clk_32m) begin
        reset_cnt <= reset_cnt + reset;
        if(reset_async) // if pressed
            reset_cnt <= 0;
    end

    localparam SPI_LEN=168;
    wire clk_32m;

    `ifdef COCOTB_SIM
        initial begin
            $dumpfile ("top.vcd");
            $dumpvars (0, top);
            #1;
        end

        assign clk_32m = clk;
    `else
        ecp5pll ecp5pll_0 (.clkin(clk), .clkout0(clk_32m));
    `endif

    // registers for SPI
    wire spi_re;
    reg [SPI_LEN-1:0] rdat = 0;
    wire [SPI_LEN-1:0] wdat;
    wire [6:0] addr;
    wire spi_we;
    wire mosi_cnt_is_zero, spi_reset;

    spi_peripheral #(.dsz(SPI_LEN)) spi_peripheral(.reset(reset), .clk(clk_32m), .spi_cipo(spi_cipo), .spi_clk(spi_clk), .spi_copi(spi_copi), .spi_cs(spi_cs), .we(spi_we), .re(spi_re), .wdat(wdat), .addr(addr), .rdat(rdat), .mosi_cnt_is_zero(mosi_cnt_is_zero), .spi_reset(spi_reset));

    assign pmod6[0] = mosi_cnt_is_zero;     // 7
    assign pmod6[1] = spi_cs;               // 6
    assign pmod6[2] = spi_reset;            // 5

endmodule
