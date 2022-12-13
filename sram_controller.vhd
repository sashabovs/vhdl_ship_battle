library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package SramHelper is
	type SramStates is (
		SRAM_OFF,
		SRAM_READ,
		SRAM_WRITE
	);

	end package SramHelper;

package body SramHelper is
end package body SramHelper;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.SramHelper.all;

entity sram is 
	port (
		CLOCK 		: in std_logic; -- clock in
		RESET_N		: in std_logic; -- reset async
		
		DATA_IN     : in std_logic_vector(15 downto 0); -- data in
		DATA_OUT    : out std_logic_vector(15 downto 0); -- data out
		ADDR_READ			: in std_logic_vector(19 downto 0); -- address in
		ADDR_WRITE			: in std_logic_vector(19 downto 0); -- address in
		
		ACTION		: in SramStates; -- operation to perform
		
		SRAM_ADDR	: out std_logic_vector(19 downto 0); -- address out
		SRAM_DQ     : inout std_logic_vector(15 downto 0); -- data in/out
		SRAM_CE_N   : out std_logic; -- chip select
		SRAM_OE_N   : out std_logic; -- output enable
		SRAM_WE_N   : out std_logic; -- write enable
		SRAM_UB_N   : out std_logic; -- upper byte mask
		SRAM_LB_N   : out std_logic -- lower byte mask
		
	);
end entity;

architecture behav of sram is

	
begin

	RamController : process(CLOCK)
	variable sleep : integer := 50_000_000;
	variable tics : integer := 0;
	begin
		if(RESET_N = '1') then -- async reset
			SRAM_CE_N<='0'; -- enables the chip (all the time?)
			SRAM_LB_N<='1'; -- mask low byte
			SRAM_UB_N<='1'; -- mask high byte
			SRAM_ADDR <= (others => '-'); -- set the address as "don't care" (must preserve low the bus)
			SRAM_DQ <= (others => 'Z'); -- set the data bus as high impedance (tristate)
		elsif rising_edge(CLOCK) then -- high clock state (do something!)
			SRAM_ADDR <= (others => '-'); -- "don't care"
			SRAM_DQ <= (others => 'Z'); -- high impedance
			SRAM_LB_N <='0'; -- unmask low byte
			SRAM_UB_N <='0'; -- unmask high byte
			if ACTION = SRAM_READ  then -- READ
				SRAM_ADDR <= ADDR_READ; -- notify the address
				DATA_OUT <= SRAM_DQ(15 downto 0); -- read the data
				SRAM_OE_N <= '0';
				SRAM_WE_N <= '1';
			elsif ACTION = SRAM_WRITE  then -- WRITE
				SRAM_ADDR <= ADDR_WRITE; -- notify the address
				SRAM_DQ <= DATA_IN; -- send the data
				SRAM_OE_N <= '1';
				SRAM_WE_N <= '0';
			elsif ACTION = SRAM_OFF  then -- WRITE
				SRAM_OE_N <= '1';
				SRAM_WE_N <= '1';
			end if;
		end if;
	end process;
	
end architecture;