library work;
use work.DataStructures.Coordinates;
use work.DataStructures.ArrayOfShells;
use work.DataStructures.ShipType;
use work.DataStructures.ShipObject;
use work.DataStructures.ShipArray;
use work.DataStructures.GraphicMemoryType;

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity hw_image_generator is
	generic (
		screen_w : integer := 5;
		screen_h : integer := 5
	);
	port (
		disp_ena : in std_logic; --display enable ('1' = display time, '0' = blanking time)
		row : in integer; --row pixel coordinate
		column : in integer; --column pixel coordinate

		first_border_coord : in Coordinates;
		second_border_coord : in Coordinates;

		cannon_1_pos : in Coordinates;
		shells_1 : in ArrayOfShells;
		ships_1 : in ShipArray;

		score_1 : in integer;

		--graphic_memory : in GraphicMemoryType := (others => (others => '0'));

		ship_1_memory_begin : in integer;
		ship_1_image_width : in integer;
		ship_1_image_height : in integer;
		data : in std_logic_vector (7 downto 0);
		write_address : in integer range 0 to 20_000;
		game_clk : in std_logic;

		--graphic_memory_q : in std_logic_vector (31 downto 0);

		-- output
		--graphic_memory_read_address : out integer range 0 to 20_000;

		red : out std_logic_vector(7 downto 0) := (others => '0'); --red magnitude output to DAC
		green : out std_logic_vector(7 downto 0) := (others => '0'); --green magnitude output to DAC
		blue : out std_logic_vector(7 downto 0) := (others => '0')); --blue magnitude output to DAC
end hw_image_generator;

architecture a1 of hw_image_generator is
	type MEM is array(0 to 1000) of std_logic_vector(7 downto 0);
	signal ram_block : MEM := (others => (others => '0'));
begin

	process (game_clk)
	begin
		if (rising_edge(game_clk)) then
			ram_block(write_address) <= data;
		end if;
	end process;


	process (disp_ena, row, column)
		--type num is array (0 to 2, 0 to 4) of std_logic_vector (14 downto 0); 
		variable ship_array_index : integer;
	begin
		if (disp_ena = '1') then --display time

			-- game area
			if (row > first_border_coord.y and column > first_border_coord.x and row < second_border_coord.y and column < second_border_coord.x) then
				red <= (others => '0');
				green <= (others => '0');
				blue <= (others => '1');
			end if;
			-- shells 1
			for i in 0 to 9 loop
				if (shells_1(i).enabled = '1') then
					if (shells_1(i).cord.x > column - 5 and shells_1(i).cord.x < column + 5 and shells_1(i).cord.y > row - 5 and shells_1(i).cord.y < row + 5) then
						red <= (others => '1');
						green <= (others => '0');
						blue <= (others => '0');
					end if;
				end if;
			end loop;

			-- cannon 1
			if (column > cannon_1_pos.x - 10 and column < cannon_1_pos.x + 10 and row > cannon_1_pos.y - 10 and row < cannon_1_pos.y + 10) then
				red <= (others => '0');
				green <= (others => '1');
				blue <= (others => '0');
			end if;

			-- ships 1
			for i in 0 to 9 loop
				if (column >= ships_1(i).pos1.x and column < ships_1(i).pos1.x + ship_1_image_width and row >= ships_1(i).pos1.y and row < ships_1(i).pos1.y + ship_1_image_height) then
					--red <= ships_1(i).ship_type.color(23 downto 16);
					--green <= ships_1(i).ship_type.color(15 downto 8);
					--blue <= ships_1(i).ship_type.color(7 downto 0);

					ship_array_index := (ship_1_image_width * (row - ships_1(i).pos1.y) + (column - ships_1(i).pos1.x)) * 4;
					--graphic_memory_read_address <= ship_array_index;

					-- if (graphic_memory_q(7 downto 0) = "11111111") then
					-- 	blue <= graphic_memory_q(31 downto 24);
					-- 	green <= graphic_memory_q(23 downto 16);
					-- 	red <= graphic_memory_q(15 downto 8);
					-- end if;

					if (ram_block(ship_array_index + 3) = "11111111") then
						blue <= ram_block(ship_array_index);
						green <= ram_block(ship_array_index + 1);
						red <= ram_block(ship_array_index + 2);
					end if;

				end if;
			end loop;

			-- border
			if (row > first_border_coord.y and column > first_border_coord.x and row < second_border_coord.y and column < second_border_coord.x) then
			else
				red <= (others => '1');
				green <= (others => '1');
				blue <= (others => '0');
			end if;

			-- score 1 dont work
		else --blanking time
			red <= (others => '0');
			green <= (others => '0');
			blue <= (others => '0');
		end if;

	end process;
end a1;