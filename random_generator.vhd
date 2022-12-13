library ieee;
use ieee.std_logic_1164.all;

entity random_gen is
	port (
		reset : in std_logic;
		clk : in std_logic;
		count : out std_logic_vector (14 downto 0)
	);
end entity;

architecture a1 of random_gen is
	-- startin seed
	signal count_i : std_logic_vector (14 downto 0) := "101100111010001";
	signal feedback : std_logic;

begin
	-- calc new element
	feedback <= not(count_i(14) xor count_i(13));

	process (clk)
	begin
		if (rising_edge(clk)) then
			-- reset
			if (reset = '1') then
				count_i <= "101100111010001";
			else
				-- shift to left with serial in as feedback 
				count_i <= count_i(13 downto 0) & feedback;
			end if;
		end if;
	end process;

	-- send out value
	count <= count_i;

end architecture;