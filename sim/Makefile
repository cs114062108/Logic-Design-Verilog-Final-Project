.PHONY: sim1 sim2 clean

DIRS = . part1 part2

sim1:
	@bash ./part1/part1_sim.sh

sim2:
	@bash ./part2/part2_sim.sh

clean:
	@for d in $(DIRS); do \
		rm -rf \
			$$d/*.vcd \
			$$d/*.fsdb \
			$$d/*.log \
			$$d/*.history \
			$$d/novas* \
			$$d/nWaveLog \
			$$d/vfastLog \
			$$d/xcelium.d \
			$$d/BSSLib.lib++ \
			$$d/simv* \
			$$d/*.key \
			$$d/csrc; \
	done