install ghdl
https://github.com/ghdl/ghdl/releases/download/nightly/MINGW64-mcode-standalone.zip
install gtkWaveform
https://jztkft.dl.sourceforge.net/project/gtkwave/gtkwave-3.3.100-bin-win32/gtkwave-3.3.100-bin-win32.zip

bash:
export src="test.vhd queue.vhd vga_controller.vhd hw_image_generator.vhd main.vhd vga_tb.vhd"
ghdl -s --ieee=synopsys ${src}; ghdl -a --ieee=synopsys ${src}; ghdl -e --ieee=synopsys vga_tb; ghdl -r --ieee=synopsys vga_tb --wave=wave.ghw

power shell:
$src="data_structures.vhd", "cannon.vhd", "core.vhd", "queue.vhd", "vga_controller.vhd", "hw_image_generator.vhd", "main.vhd", "ships.vhd", "random_generator.vhd", "vga_tb.vhd"
ghdl -s --ieee=synopsys @src; ghdl -a --ieee=synopsys @src; ghdl -e --ieee=synopsys vga_tb; ghdl -r --ieee=synopsys vga_tb --wave=wave.ghw

to analize image file:
python3 vhdl_image_viewer.py

install tkinter!!!(python lib)

