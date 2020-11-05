# spi reset

    assign spi_reset = reset | spi_cs;  // combined reset

    ...

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


![simulation](pics/spi-reset-sim.png)

![no reset](pics/no-reset-scope.png)

![reset](pics/reset-scope.png)
