import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, ClockCycles, with_timeout, Timer
from kneesonic.cocotb.spi import SPIReaderCocotb
import logging
from kneesonic.hardware.configuration import RegGlobal, SPIConf

async def finish_reset(dut):
    await ClockCycles(dut.clk, 1)
    if dut.reset.value:
        await FallingEdge(dut.reset) # wait for power on reset
        await ClockCycles(dut.clk, 100)
        
@cocotb.test()
async def test_spi(dut):
    clock = Clock(dut.clk, 100, units="us")  # Create a 10us period clock on port clk
    cocotb.fork(clock.start())  # Start the clock

    dut.spi_cs <= 1
    dut.spi_copi <= 0
    dut.spi_clk <= 0

    spi = SPIReaderCocotb(dut)

    await finish_reset(dut)

    assert await spi.read_reg(RegGlobal.SPI_LEN, flush=False) == 0

    await Timer(10, units="ms")

