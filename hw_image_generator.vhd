library work;
use work.DataStructures.all;


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
		cannon_2_pos : in Coordinates;
		shells_1 : in ArrayOfShells;
		shells_2 : in ArrayOfShells;
		ships_1 : in ShipArray;
		ships_2 : in ShipArray;

		score_1 : in integer;
		score_2 : in integer;

		--graphic_memory : in GraphicMemoryType := (others => (others => '0'));

		-- ship_1_memory_begin : in integer;
		-- ship_1_image_width : in integer;
		-- ship_1_image_height : in integer;
		data : in std_logic_vector (15 downto 0);
		-- write_address : in integer range 0 to 1300;
		game_clk : in std_logic;
		we : in std_logic;

		--graphic_memory_q : in std_logic_vector (31 downto 0);

		-- output
		--graphic_memory_read_address : out integer range 0 to 1300;
		sram_addres_read : out std_logic_vector(19 downto 0);
		red : out std_logic_vector(7 downto 0) := (others => '0'); --red magnitude output to DAC
		green : out std_logic_vector(7 downto 0) := (others => '0'); --green magnitude output to DAC
		blue : out std_logic_vector(7 downto 0) := (others => '0'); --blue magnitude output to DAC

		LED : out std_logic_vector(7 downto 0)
	);
end hw_image_generator;

architecture a1 of hw_image_generator is
	type MEM is array(0 to 1300) of std_logic_vector(7 downto 0);
	signal ram_block : MEM := (others => (others => '0'));
begin
	-- process (game_clk)
	-- variable pos : integer := 0;
	-- begin
	-- 	if (rising_edge(game_clk)) then
	-- 		if (we = '1') then
	-- 			ram_block(pos) <= data;
	-- 			LED <= data;
	-- 			pos := pos + 1;
	-- 		end if;
	-- 	end if;
	-- end process;
	process (disp_ena, row, column)
		--type num is array (0 to 2, 0 to 4) of std_logic_vector (14 downto 0); 
		variable ship_array_index : integer;
		variable tmp_color : std_logic_vector(0 to 7);

		variable letter_pos : Coordinates := (x => 100, y => 550);
		constant letter_size : Coordinates := (x => 12, y => 14);

		variable ship_memory_offset : integer := 0;

		variable sleep : integer := 0;
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

			-- shells 2
			for i in 0 to 9 loop
				if (shells_2(i).enabled = '1') then
					if (shells_2(i).cord.x > column - 5 and shells_2(i).cord.x < column + 5 and shells_2(i).cord.y > row - 5 and shells_2(i).cord.y < row + 5) then
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

			-- cannon 2
			if (column > cannon_2_pos.x - 10 and column < cannon_2_pos.x + 10 and row > cannon_2_pos.y - 10 and row < cannon_2_pos.y + 10) then
				red <= (others => '0');
				green <= (others => '1');
				blue <= (others => '0');
			end if;

			-- ships 1

			
			for i in 0 to 4 loop


				if (column >= ships_1(i).pos1.x - 1 and column < ships_1(i).pos1.x + ships_1(i).ship_type.ship_image_width and row >= ships_1(i).pos1.y and row < ships_1(i).pos1.y + ships_1(i).ship_type.ship_image_height) then
					--red <= ships_1(i).ship_type.color(23 downto 16);
					--green <= ships_1(i).ship_type.color(15 downto 8);
					--blue <= ships_1(i).ship_type.color(7 downto 0);

					--ship_array_index := (ship_1_image_width * (ships_1(i).pos1.y + ship_1_image_height - 1 - (row - ships_1(i).pos1.y)) + (column - ships_1(i).pos1.x)) + 1;

					if (ships_1(i).ship_type.id = destroyer_id) then
						ship_memory_offset := 1300;
					else
						ship_memory_offset := 0;
					end if;

					ship_array_index := ship_memory_offset + (ships_1(i).ship_type.ship_image_width * ((row - ships_1(i).pos1.y)) + (column - ships_1(i).pos1.x)) + 1;
					--graphic_memory_read_address <= ship_array_index;

					-- if (graphic_memory_q(7 downto 0) = "11111111") then
					-- 	blue <= graphic_memory_q(31 downto 24);
					-- 	green <= graphic_memory_q(23 downto 16);
					-- 	red <= graphic_memory_q(15 downto 8);
					-- end if;

					--if (ram_block(ship_array_index + 3) = "11111111") then
					if (column /= ships_1(i).pos1.x + ships_1(i).ship_type.ship_image_width) then
						sram_addres_read <= std_logic_vector(to_unsigned(ship_array_index, 20));
					end if;

					if (column /= ships_1(i).pos1.x - 1) then
						if (data(7 downto 0) = x"FF") then
							blue <= data(15 downto 8);
							green <= data(15 downto 8);
							red <= data(15 downto 8);
						end if;

					end if;
					--end if;

				end if;

			end loop;

			-- ships 2
			for i in 0 to 4 loop
				if (column >= ships_2(i).pos1.x - 1 and column < ships_2(i).pos1.x + ships_2(i).ship_type.ship_image_width and row >= ships_2(i).pos1.y and row < ships_2(i).pos1.y + ships_2(i).ship_type.ship_image_height) then
					if (ships_2(i).ship_type.id = destroyer_id) then
						ship_memory_offset := 1300;
					else
						ship_memory_offset := 0;
					end if;

					ship_array_index := ship_memory_offset + (ships_2(i).ship_type.ship_image_width * ((row - ships_2(i).pos1.y)) + (column - ships_2(i).pos1.x)) + 1;

					if (column /= ships_2(i).pos1.x + ships_2(i).ship_type.ship_image_width) then
						sram_addres_read <= std_logic_vector(to_unsigned(ship_array_index, 20));
					end if;

					if (column /= ships_2(i).pos1.x - 1) then
						if (data(7 downto 0) = x"FF") then
							blue <= data(15 downto 8);
							green <= data(15 downto 8);
							red <= data(15 downto 8);
						end if;
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

			if (row >= letter_pos.y - 1 and column >= letter_pos.x and row < letter_pos.y + letter_size.y and column < letter_pos.x + letter_size.x) then

				ship_array_index := (5108 + 792 * (row - letter_pos.y) + (letter_size.x * 5 + column - letter_pos.x) + 1) / 2;

				if (column /= letter_pos.x + letter_size.x) then
					sram_addres_read <= std_logic_vector(to_unsigned(ship_array_index, 20));
				end if;

				if (column /= letter_pos.x - 1) then



					if ((column - letter_pos.x) mod 2 = 0) then
						if (data(15 downto 8) = x"01") then
							blue <= x"00";
							green <= x"00";
							red <= x"00";
						end if;
					else
						if (data(7 downto 0) = x"01") then
							blue <= x"00";
							green <= x"00";
							red <= x"00";
						end if;
					end if;

				end if;
			end if;

			--if (row < 300) then
				if (row < 15) then
				sram_addres_read <= std_logic_vector(to_unsigned((column + 5108 + row * 792)/2, 20));

			
				if ((column - letter_pos.x) mod 2 = 0) then
					if (data(15 downto 8) = x"01") then
						blue <= x"00";
						green <= x"00";
						red <= x"00";
					elsif (data(15 downto 8) = x"00") then
						blue <= x"FF";
						green <= x"FF";
						red <= x"FF";
					end if;
				else
					if (data(7 downto 0) = x"01") then
						blue <= x"00";
						green <= x"00";
						red <= x"00";
					elsif (data(7 downto 0) = x"00") then
						blue <= x"FF";
						green <= x"FF";
						red <= x"FF";
					end if;
				end if;
			end if;


		else --blanking time
			red <= (others => '0');
			green <= (others => '0');
			blue <= (others => '0');
		end if;

	end process;
end a1;