
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.DataStructures.Coordinates;

entity cannon is
	generic (
		-- cannon move speed
		speed : integer := 10;

		-- cannon start position
		start_pos_x : integer := 0;
		start_pos_y : integer := 0;

		-- screen working area borders
		screen_top : integer := 100;
		screen_bottom : integer := 100
	);
	port (
		-- INPUT
		--clock
		clk : in std_logic;

		-- move signals
		up : in std_logic;
		down : in std_logic;

		-- synchronous reset
		core_reset : in std_logic;

		-- OUTPUT
		-- current position of the cannon
		coords_out : out Coordinates
	);
end cannon;

architecture a1 of cannon is
	-- current cannon position
	signal coords : Coordinates := (x => start_pos_x, y => start_pos_y);
begin
	-- send out cannon coordinats
	coords_out <= coords;

	process (clk)
		-- variable for slowing the speed of the cannon
		variable ticks : integer := 0;
		-- variable to restrict movement
		variable cannon_height : integer := 10;
	begin
		if (rising_edge(clk)) then
			
			if (core_reset = '1') then
				-- reset
				coords.x <= start_pos_x;
				coords.y <= start_pos_y;
			else

				-- decrease cannon move speed
				ticks := ticks + 1;
				if (ticks = speed) then
					ticks := 0;
					-- cannon position is in center
					-- can only go offscreen by a quarter of the size
					-- increase the position of the cannon until it reaches the lower position of the game area
					if (up = '1' and down = '0' and coords.y < screen_bottom - cannon_height/2) then
						coords.y <= coords.y + 1;
					end if;

					-- decrement the position of the cannon until it reaches the highest position of the game area
					if (down = '1' and up = '0' and coords.y > screen_top + cannon_height/2) then
						coords.y <= coords.y - 1;
					end if;
				end if;
			end if;
		end if;
	end process;
end a1;