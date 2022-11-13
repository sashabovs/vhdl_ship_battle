
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.DataStructures.Coordinates;
use work.DataStructures.ShipType;
use work.DataStructures.ShipObject;
use work.DataStructures.ShipArray;

entity ships is
	generic (
		--depth of fifo
		size : integer := 10;
		update_period_in_clk : integer := 20;
		screen_w : integer;
		screen_h : integer
	);
	port (
		-- input
		clk : in std_logic;
		reset : in std_logic;

		ship_to_delete : in integer;

		-- output
		ships_all : out ShipArray
	);
end ships;

architecture a1 of ships is
	component random_gen is
		port (
			reset : in std_logic;
			clk : in std_logic;
			count : out std_logic_vector (14 downto 0) -- lfsr output
		);
	end component;

	constant destroyer : ShipType := (
		color => "011111000000000000011111",
		value => 1
	);
	constant battleShip : ShipType := (
		color => "000000011111000000011111",
		value => 5
	);
	constant civilShip : ShipType := (
		color => "000000000000001111111111",
		value => - 2
	);

	signal ships_all_inner : ShipArray := (others => (pos1 => (x => - 100, y => - 100), ship_type => destroyer));
	signal random_num : std_logic_vector (14 downto 0);

begin
	random_gen_1 : random_gen
	port map(
		reset => reset,
		clk => clk,
		count => random_num
	);

	ships_all <= ships_all_inner;
	-- for i in 4 to 6 loop
	-- 	ships(i) <= (pos <= (x <= 0, y <= 0), ship_type <= battleShip);
	-- end loop;

	-- for i in 7 to 9 loop
	-- 	ships(i) <= (pos <= (x <= 0, y <= 0), ship_type <= civilShip);
	-- end loop;

	process (clk, reset)
		variable init_i : integer := 0;
		variable ship_y : integer;
		variable ship_type : ShipType;
		variable ticks : integer := 0;
	begin
		if (reset = '1') then

		elsif (rising_edge(clk)) then
			if (init_i < 10) then
				-- initialization
				if (init_i <= 3) then
					ship_type := destroyer;
				elsif (init_i <= 6) then
					ship_type := battleShip;
				else
					ship_type := civilShip;
				end if;

				ship_y := screen_h * to_integer(unsigned(random_num))/(2 ** 15 - 1);
				-- ship := (pos1 => (x => 0, y => ship_y), ship_type => ship_type);
				ships_all_inner(init_i) <= (pos1 => (x => (screen_w/10) * 9, y => ship_y), ship_type => ship_type);
				init_i := init_i + 1;
			else
				if (ship_to_delete < size) then
					ships_all_inner(ship_to_delete).pos1.y <= 0;
				end if;

				ticks := ticks + 1;
				if (ticks = update_period_in_clk) then
					ticks := 0;
					for i in 0 to size - 1 loop
						if (ships_all_inner(i).pos1.y < screen_h) then
							ships_all_inner(i).pos1.y <= ships_all_inner(i).pos1.y + 1;
						else
							ships_all_inner(i).pos1.y <= 0;
						end if;
					end loop;
				end if;
			end if;
		end if;
	end process;
end a1;