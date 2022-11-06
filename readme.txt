install ghdl
install gtkWaveform

export src="test.vhd queue.vhd vga_controller.vhd hw_image_generator.vhd main.vhd vga_tb.vhd"
ghdl -s --ieee=synopsys ${src}; ghdl -a --ieee=synopsys ${src}; ghdl -e --ieee=synopsys vga_tb; ghdl -r --ieee=synopsys vga_tb --wave=wave.ghw

power shell:
$src="test.vhd", "queue.vhd", "vga_controller.vhd", "hw_image_generator.vhd", "main.vhd", "vga_tb.vhd"
ghdl -s --ieee=synopsys @src; ghdl -a --ieee=synopsys @src; ghdl -e --ieee=synopsys vga_tb; ghdl -r --ieee=synopsys vga_tb --wave=wave.ghw

to analize image file:
./vhdl_image_viewer.py

