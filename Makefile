PROJ = spiperipheral

PIN_DEF=mv_ecp.lpf
PACKAGE = CABGA256
DEVICE=12k
BOARD = ECP5_MV_BOARD
SEED = 8
PI_ADDR = pi@raspberrypi.local

# $@: The filename representing the target.
# $%: The filename element of an archive member specification.
# $<: The filename of the first prerequisite.
# $?: The names of all prerequisites that are newer than the target, separated by spaces.
# $^: The filenames of all the prerequisites, separated by spaces. This list has duplicate filenames removed since for most uses, such as compiling, copying, etc., duplicates are not wanted.

SRC = top.v spi_peripheral.v ecp5pll.v

# cocotb setup
MODULE = spi_test
TOPLEVEL = top
VERILOG_SOURCES = top.v spi_peripheral.v
#COMPILE_ARGS += -Pspi_peripheral.dsz=120
include $(shell cocotb-config --makefiles)/Makefile.sim

all: $(PROJ).bit

lint:
	verible-verilog-lint $(VERILOG_SOURCES) --rules_config ../verible.rules

%.blif %.json: $(SRC)
	yosys -l yosys.log -D$(BOARD) -p 'synth_ecp5 -top top -json spiperipheral.json -blif $@' $^ # ecp5 version

%_out.config: %.json $(PIN_DEF)
	nextpnr-ecp5  -l nextpnr.log --seed $(SEED) --freq 32 --package $(PACKAGE) --$(DEVICE) --speed 6 --json $< --lpf $(PIN_DEF) --textcfg $@

%.bit: %_out.config
	ecppack --svf-rowsize 100000 --compress --svf $(PROJ).svf --input $< --bit $@

gtkwave:
	gtkwave spi_peripheral.vcd spi_coco.gtkw

ecp-prog: $(PROJ).bit
	scp $(PROJ).bit $(PI_ADDR):~/
	ssh $(PI_ADDR) "~/prog_ecp5_fpga.sh $(PROJ).bit"

clean::
	rm -f $(PROJ).json $(PROJ)_out.config  $(PROJ).bit

.SECONDARY:
.PHONY: all prog clean
