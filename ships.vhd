
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.DataStructures.all;
entity ships is
	generic (
		--depth of fifo
		size : integer := 5;
		update_period_in_clk : integer := 20;
		screen_w : integer;
		screen_h : integer;

		-- 0 , 1
		reverse : integer
	);
	port (
		-- input
		clk : in std_logic;
		core_reset : in std_logic;
		start_init : in std_logic;
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

	signal ships_all_inner : ShipArray := (others => (pos1 => (x => - 100, y => - 100), ship_type => destroyer));
	signal random_num : std_logic_vector (14 downto 0);

begin
	random_gen_1 : random_gen
	port map(
		--no reset
		reset => '0',
		clk => clk,
		count => random_num
	);

	ships_all <= ships_all_inner;

	process (clk)
		variable init_i : integer := 0;
		variable ship_x : integer;
		variable ship_y : integer;
		variable ship_type : ShipType;
		variable ticks : integer := 0;
	begin
		if (rising_edge(clk)) then
			if (core_reset = '1') then
				init_i := 0;
			else
				if (init_i < 5 and start_init = '1') then
					-- initialization
					if (init_i <= 1) then
						ship_type := destroyer;
						ship_x := (screen_w/20) * 4 + ((screen_w/20) * 12 - destroyer.ship_image_width) * reverse;
					elsif (init_i <= 2) then
						ship_type := battleShip;
						ship_x := (screen_w/20) * 3 + ((screen_w/20) * 14 - battleShip.ship_image_width) * reverse;
					else
						ship_type := civilShip;
						ship_x := (screen_w/20) * 2 + ((screen_w/20) * 16 - civilShip.ship_image_width) * reverse;
					end if;
					
					if (init_i = 0 or init_i = 2 or init_i = 3) then
						ship_y := screen_h * to_integer(unsigned(random_num))/(2 ** 15 - 1);
					else
						ship_y := ship_y + (screen_h + 100) / 2;
					end if;
					-- ship := (pos1 => (x => 0, y => ship_y), ship_type => ship_type);
					ships_all_inner(init_i) <= (pos1 => (x => ship_x, y => ship_y), ship_type => ship_type);
					init_i := init_i + 1;
				else
					if (ship_to_delete < size) then
						ships_all_inner(ship_to_delete).pos1.y <= ships_all_inner(ship_to_delete).pos1.y + screen_h + 100;
					end if;

					ticks := ticks + 1;
					if (ticks = update_period_in_clk) then
						ticks := 0;
						for i in 0 to size - 1 loop
							if (ships_all_inner(i).pos1.y > -100) then

								ships_all_inner(i).pos1.y <= ships_all_inner(i).pos1.y - 1;
							else
								ships_all_inner(i).pos1.y <= screen_h;
							end if;
						end loop;
					end if;
				end if;
			end if;
		end if;
	end process;
end a1;