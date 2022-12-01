library ieee;
use ieee.std_logic_1164.all;

entity random_gen is
	port (
		reset : in std_logic;
		clk : in std_logic;
		count : out std_logic_vector (14 downto 0) -- lfsr output
	);
end entity;

architecture a1 of random_gen is
	signal count_i : std_logic_vector (14 downto 0) := "101100111010001";
	signal feedback : std_logic;

begin
	feedback <= not(count_i(14) xor count_i(13));
	-- LFSR size 4

	process (clk)
	begin
		if (rising_edge(clk)) then
			if (reset = '1') then
				count_i <= "101100111010001";
			else
				count_i <= count_i(13 downto 0) & feedback;
			end if;
		end if;
	end process;
	count <= count_i;

end architecture;