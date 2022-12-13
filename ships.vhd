
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.DataStructures.all;
entity ships is
	generic (
		-- depth of fifo
		size : integer := 5;
		-- speed of ships
		update_period_in_clk : integer := 20;
		-- screen parameters
		screen_w : integer;
		screen_h : integer;

		-- position of ships (0 - left side, 1 - right side)
		reverse : integer
	);
	port (
		-- INPUT
		-- clock
		clk : in std_logic;
		-- reset 
		core_reset : in std_logic;
		-- start of ship initialization
		start_init : in std_logic;
		-- index of ship to delete
		ship_to_delete : in integer;

		-- OUTPUT
		-- all elements
		ships_all : out ShipArray
	);
end ships;

architecture a1 of ships is

	-- random generator
	component random_gen is
		port (
			reset : in std_logic;
			clk : in std_logic;
			count : out std_logic_vector (14 downto 0) 
		);
	end component;

	-- ship array 
	signal ships_all_inner : ShipArray := (others => (pos1 => (x => - 100, y => - 100), ship_type => destroyer));
	-- random number
	signal random_num : std_logic_vector (14 downto 0);

begin
	random_gen_1 : random_gen
	port map(
		-- no reset
		reset => '0',
		clk => clk,
		count => random_num
	);

	-- send out all ships
	ships_all <= ships_all_inner;

	process (clk)
		-- variable for initialization, shows the number of initialized ships
		variable init_i : integer := 0;
		-- starting position of the ship
		variable ship_x : integer;
		variable ship_y : integer;
		-- ship type (destroyer - 1, battleship - 5, civil ship - -2)
		variable ship_type : ShipType;
		-- variable for slowing the speed of ships
		variable ticks : integer := 0;
		-- buffer for playing area
		constant playing_area_buffer : integer := 100;
	begin
		if (rising_edge(clk)) then
			-- on reset, all ships are re-initialized
			if (core_reset = '1') then
				init_i := 0;
			else
				-- initialization
				if (init_i < 5 and start_init = '1') then
					-- set ship type and x-position
					-- the ship is positioned by the upper left corner
					if (init_i <= 1) then
						ship_type := destroyer;
						-- 4/20 or 16/20 = 4/20 from other side
						ship_x := (screen_w/20) * 4 + ((screen_w/20) * 12 - destroyer.ship_image_width) * reverse;
					elsif (init_i <= 2) then
						ship_type := battleShip;
						-- 3/20 or 17/20 = 3/20 from other side
						ship_x := (screen_w/20) * 3 + ((screen_w/20) * 14 - battleShip.ship_image_width) * reverse;
					else
						ship_type := civilShip;
						-- 2/20 or 18/20 = 2/20 from other side
						ship_x := (screen_w/20) * 2 + ((screen_w/20) * 16 - civilShip.ship_image_width) * reverse;
					end if;
					
					-- the first ships of the new type are located at a random height
					-- the next ships of the same type are located below them
					if (init_i = 0 or init_i = 2 or init_i = 3) then
						-- random generator returns a number from 0 to 2^15-1, so we get screen_h*0->1
						ship_y := screen_h * to_integer(unsigned(random_num))/(2 ** 15 - 1);
					else
						-- the next ship is located below, at a distance of half the playing area
						ship_y := ship_y + (screen_h + playing_area_buffer) / 2;
					end if;

					-- create ship with generated parameters
					ships_all_inner(init_i) <= (pos1 => (x => ship_x, y => ship_y), ship_type => ship_type);
					init_i := init_i + 1;
				else
					-- if the index of the removed ship is valid, move the ship off the screen
					-- so ships will never overlap each other
					if (ship_to_delete < size) then
						ships_all_inner(ship_to_delete).pos1.y <= ships_all_inner(ship_to_delete).pos1.y + screen_h + playing_area_buffer;
					end if;


					-- move all ships
					-- if ships have reached the top of the play area, move them down
					ticks := ticks + 1;
					if (ticks = update_period_in_clk) then
						ticks := 0;
						for i in 0 to size - 1 loop
							if (ships_all_inner(i).pos1.y > -playing_area_buffer) then
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