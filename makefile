IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave

SRC_DIR := src
TB_DIR  := tb
OUT     := sim/sim.vvp
VCD     := sim/dump.vcd
TB      ?= tb

IVERILOG_FLAGS := -g2012 -Wall -s $(TB) -I $(SRC_DIR)

.PHONY: all compile run wave clean

all: wave

compile:
	@mkdir -p sim
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(OUT) $(TB_DIR)/$(TB).v $(SRC_DIR)/*.v

run: compile
	$(VVP) $(OUT)

wave: run
	@if [ -f "$(VCD)" ]; then $(GTKWAVE) "$(VCD)"; else echo "Chưa thấy $(VCD). Đặt $$dumpfile(\"$(VCD)\") trong tb/$(TB).v"; fi

clean:
	@rm -f $(OUT) $(VCD)
