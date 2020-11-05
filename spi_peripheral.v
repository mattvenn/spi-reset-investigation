// spi_peripheral.v: SPI Bus interface for 128 x 32
// 2009-02-28 E. Brombaugh
// 2009-03-22 E. Brombaugh - backported early read logic
//
// This is a simple SPI (serial peripheral interface) peripheral module.
// These SPI parameters are used in this module:
//   CPOL = 0 (spi_clk idles low)
//   CPHA = 0 (data clocked in on rising edge when CPOL is 1)
//
// Note:  addr/wdat are synchronous to the SPI clock. we & re are synchronized
//
// A SPI transfer consists of 40 bits, MSB first.
// The first bit is read/write_n.
// The next 7 are address bits.
// The last 32 are data bits
// Read data is sent in current transfer based on early address/direction

//`timescale 1 ns/1 ps
`default_nettype none

module spi_peripheral
#(
    parameter asz = 7,              // address size
    parameter dsz = 32              // databus word size
) (
    input wire clk,
    input wire reset,
    input wire spi_clk,
    input wire spi_copi,
    output wire spi_cipo,
    input wire spi_cs,
    output reg we,
    output reg re,
    output reg [dsz-1:0] wdat,
    output reg [asz-1:0]  addr,
    input wire [dsz-1:0] rdat,
    output reg rd,
    output wire spi_reset,
    output wire mosi_cnt_is_zero);

    reg [12:0]  mosi_cnt;           // input bit counter
    reg [dsz-1:0] mosi_shift;       // shift reg
    reg eoa;                        // end of address flag
    reg eot;                        // end of transfer flag
    assign spi_reset = reset | spi_cs;  // combined reset

    `ifdef COCOTB_SIM
        initial begin
            $dumpfile ("spi_peripheral.vcd");
            $dumpvars (0, spi_peripheral);
            #1;
        end
    `endif

    assign mosi_cnt_is_zero = mosi_cnt == 0;
    always @(posedge spi_clk or posedge spi_reset)
        if (spi_reset)
        begin
            mosi_cnt <= 'b0;
            mosi_shift <= 'b0;
            eoa <= 'b0;
            re <= 'b0;
            rd <= 'b0;
            eot <= 'b0;
        end else begin
            // Counter keeps track of bits received
            mosi_cnt <= mosi_cnt + 1;

            // Shift register grabs incoming data
            mosi_shift <= {mosi_shift[dsz-2:0], spi_copi};

            // Grab Read bit
            if(mosi_cnt == 0)
                rd <= spi_copi;

            // Grab Address
            if(mosi_cnt == asz)
            begin
                addr <= {mosi_shift[asz-2:0],spi_copi};
                eoa <= 1'b1;
            end

            // Generate Read pulse, lasts for one spi_clk pulse
            re <= rd & (mosi_cnt == asz);

            if(mosi_cnt == (asz+dsz))
            begin
                // Grab data
                wdat <= {mosi_shift[dsz-2:0],spi_copi};

                // End-of-transmission (used to generate Write pulse)
                eot <= 1'b1;
            end
        end

    // outgoing shift register is clocked on falling edge
    reg [dsz-1:0] miso_shift;
    always @(negedge spi_clk or posedge spi_reset)
        if (spi_reset)
        begin
            miso_shift <= 'b0;
        end
        else
        begin
            if(re)
                miso_shift <= rdat;
            else
                miso_shift <= {miso_shift[dsz-2:0],1'b0};
        end

    // MISO is just msb of shift reg
    assign spi_cipo = eoa ? miso_shift[dsz-1] : 1'b0;

    // Delay/Sync & edge detect on eot to generate we
    reg [2:0] we_dly;
    always @(posedge clk)
        if(reset)
        begin
            we_dly <= 0;
            we <= 0;
        end
        else
        begin
            we_dly <= {we_dly[1:0],eot};
            we <= ~we_dly[2] & we_dly[1] & ~rd;
        end

endmodule
