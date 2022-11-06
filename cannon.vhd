
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.DataStructures.Coordinates;

entity cannon is
	generic (
		speed : integer := 10;
		start_pos_x : integer := 0;
		start_pos_y : integer := 0;

		screen_w: integer := 100;
		screen_h: integer := 100
	);
	port (
		-- input
		clk : in std_logic;
		up : in std_logic;
		down : in std_logic;

		-- output
		coords_out : out Coordinates
	);
end cannon;

architecture a1 of cannon is
	signal coords : Coordinates := (x => start_pos_x, y => start_pos_y);
begin
	coords_out <= coords;

	process (clk)
		variable ticks : integer := 0;
	begin
		if (rising_edge(clk)) then
			ticks := ticks + 1;
			if (ticks = speed) then
				ticks := 0;
				if (up = '1' and down = '0' and coords.y < screen_h) then
					coords.y <= coords.y + 1;
				end if;

				if (down = '1' and up = '0' and coords.y > 0) then
					coords.y <= coords.y - 1;
				end if;
			end if;
		end if;

	end process;
end a1;