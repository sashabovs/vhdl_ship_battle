library ieee;
use ieee.std_logic_1164.all;

entity single_clock_ram is
	port (
		clock : in std_logic;
		data : in std_logic_vector (7 downto 0);
		write_address : in integer range 0 to 1300;
		read_address : in integer range 0 to 1300;
		we : in std_logic;
		q : out std_logic_vector (31 downto 0)
	);
end single_clock_ram;

architecture rtl of single_clock_ram is
	--type MEM is array(0 to 1300) of std_logic_vector(7 downto 0);
	--signal ram_block : MEM := (others => (others => '0'));
begin
	process (clock)
	begin
		if (rising_edge(clock)) then
			if (we = '1') then
				--ram_block(write_address) <= data;
			end if;
			--q <= ram_block(read_address) & ram_block(read_address + 1) & ram_block(read_address + 2) & ram_block(read_address + 3);
			--q <= ram_block(read_address) & ram_block(read_address + 1) & ram_block(read_address) & ram_block(read_address + 1);
			-- VHDL semantics imply that q doesn't get data 
			-- in this clock cycle
		end if;
	end process;
end rtl;