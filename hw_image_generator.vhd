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

		data : in std_logic_vector (15 downto 0);
		game_clk : in std_logic;
		pixel_clk : in std_logic;
		we : in std_logic;

		game_time : in integer;
		game_state : in GameStates;

		-- output
		sram_addres_read : out std_logic_vector(19 downto 0);
		red : out std_logic_vector(7 downto 0) := (others => '0'); --red magnitude output to DAC
		green : out std_logic_vector(7 downto 0) := (others => '0'); --green magnitude output to DAC
		blue : out std_logic_vector(7 downto 0) := (others => '0'); --blue magnitude output to DAC

		LED : out std_logic_vector(7 downto 0)
	);
end hw_image_generator;

architecture a1 of hw_image_generator is
	type score_digits is array(0 to 2) of integer;
	signal score_1_array : score_digits;
	signal score_2_array : score_digits;

	signal time_digits_array : DigitsArray := (others => (others => 0));
	signal score_digits_array : DigitsArray := (others => (others => 0));

	function CharToFontPos(
		cur_char : character
	) return integer is
		variable cur_char_font_num : integer;
	begin
		return character'pos(cur_char) - 32;
	end function;

	--	procedure DrawText(ToState : t_State;
	--	Minutes : integer := 0;
	--	Seconds : integer := 0) is
	--	variable TotalSeconds : integer;
	--	variable ClockCycles : integer;
	--begin
	--	TotalSeconds := Seconds + Minutes * 60;
	--	ClockCycles := TotalSeconds * ClockFrequencyHz - 1;
	--	if Counter = ClockCycles then
	--		Counter <= 0;
	--		State <= ToState;
	--	end if;
	--end procedure;

begin

	process (score_1, score_2)
	begin
		score_digits_array(0)(8) <= score_1 / 100;
		score_digits_array(0)(9) <= (score_1 mod 100) / 10;
		score_digits_array(0)(10) <= score_1 mod 10;

		score_digits_array(1)(8) <= score_2 / 100;
		score_digits_array(1)(9) <= (score_2 mod 100) / 10;
		score_digits_array(1)(10) <= score_2 mod 10;
	end process;
	
	process (game_clk)
		variable mins : integer;
		variable secs : integer;
	begin
		if (rising_edge(pixel_clk)) then
			mins := game_time / 60;
			secs := game_time mod 60;

			time_digits_array(0)(1) <= mins / 10;
			time_digits_array(0)(2) <= mins mod 10;
			-- time_digits_array(3) is ':'
			time_digits_array(0)(4) <= secs / 10;
			time_digits_array(0)(5) <= secs mod 10;
		end if;
	end process;

	process (pixel_clk)
		variable ship_array_index : integer;
		variable tmp_color : std_logic_vector(0 to 7);

		variable red_tmp : std_logic_vector(7 downto 0) := (others => '0');
		variable green_tmp : std_logic_vector(7 downto 0) := (others => '0');
		variable blue_tmp : std_logic_vector(7 downto 0) := (others => '0');

		variable letter_pos : Coordinates;

		variable ship_memory_offset : integer := 0;

		variable sleep : integer := 0;
		variable letter_num : integer := 0;

		-- variable ticks: integer:= 40_000_000;
		-- variable cur_addr: integer := 100;
		-- variable data_count: integer:= 0;
		-- variable prev_data : std_logic_vector (15 downto 0);

		variable cur_char : character;
		variable cur_char_font_num : integer;

		constant font_start_byte : integer := 5908;
		constant font_row_size_byte : integer := 1152;
	begin
		if (rising_edge(pixel_clk)) then
			if (disp_ena = '1') then --display time
				if (game_state = GAME_START) then

					red_tmp := (others => '1');
					green_tmp := (others => '1');
					blue_tmp := (others => '0');

					for text_i in 0 to 1 loop
						for i in all_texts_start_game(text_i).array_of_letters'range loop
							cur_char := all_texts_start_game(text_i).array_of_letters(i);
							cur_char_font_num := CharToFontPos(cur_char);

							letter_pos := (x => all_texts_start_game(text_i).position.x + (letter_size.x + 1) * i, y => all_texts_start_game(text_i).position.y);
							if (row >= letter_pos.y and column >= letter_pos.x - 1 and row < letter_pos.y + letter_size.y and column < letter_pos.x + letter_size.x) then

								ship_array_index := (font_start_byte + font_row_size_byte * (row - letter_pos.y) + (column - letter_pos.x + letter_size.x * (cur_char_font_num)) + 1) / 2;

								if (column /= letter_pos.x - 1) then
									if ((column - letter_pos.x) mod 2 = 0) then
										if (data(15 downto 8) = x"01") then
											red_tmp := x"00";
											green_tmp := x"00";
											blue_tmp := x"00";
										end if;
									else
										if (data(7 downto 0) = x"01") then
											red_tmp := x"00";
											green_tmp := x"00";
											blue_tmp := x"00";
										end if;
									end if;
								end if;
							end if;
						end loop;
					end loop;
				elsif (game_state = GAME_PLAY) then
					if (row < first_border_coord.y) then
						-- header
						red_tmp := (others => '1');
						green_tmp := (others => '1');
						blue_tmp := (others => '0');

						for text_i in 0 to 0 loop
							for i in all_texts_play_game_header(text_i).array_of_letters'range loop
								cur_char := all_texts_play_game_header(text_i).array_of_letters(i);
								cur_char_font_num := CharToFontPos(cur_char);
								letter_pos := (x => all_texts_play_game_header(text_i).position.x + (letter_size.x + 1) * i, y => all_texts_play_game_header(text_i).position.y);
								if (row >= letter_pos.y and column >= letter_pos.x - 1 and row < letter_pos.y + letter_size.y and column < letter_pos.x + letter_size.x) then

									ship_array_index := (font_start_byte + font_row_size_byte * (row - letter_pos.y) + (column - letter_pos.x + letter_size.x * (cur_char_font_num + time_digits_array(text_i)(i))) + 1) / 2;

									if (column /= letter_pos.x - 1) then
										if ((column - letter_pos.x) mod 2 = 0) then
											if (data(15 downto 8) = x"01") then
												red_tmp := x"00";
												green_tmp := x"00";
												blue_tmp := x"00";
											end if;
										else
											if (data(7 downto 0) = x"01") then
												red_tmp := x"00";
												green_tmp := x"00";
												blue_tmp := x"00";
											end if;
										end if;

									end if;
								end if;
							end loop;
						end loop;
					elsif (row < second_border_coord.y) then
						if (column < first_border_coord.x) then
							-- left panel
							red_tmp := (others => '1');
							green_tmp := (others => '1');
							blue_tmp := (others => '0');
						elsif (column < second_border_coord.x) then
							-- game area
							red_tmp := x"30";
							green_tmp := x"B0";
							blue_tmp := x"FF";

							-- shells 1
							for i in 0 to 9 loop
								if (shells_1(i).enabled = '1') then
									if (shells_1(i).cord.x > column - 5 and shells_1(i).cord.x < column + 5 and shells_1(i).cord.y > row - 5 and shells_1(i).cord.y < row + 5) then
										red_tmp := (others => '1');
										green_tmp := (others => '0');
										blue_tmp := (others => '0');
									end if;
								end if;
							end loop;

							-- shells 2
							for i in 0 to 9 loop
								if (shells_2(i).enabled = '1') then
									if (shells_2(i).cord.x > column - 5 and shells_2(i).cord.x < column + 5 and shells_2(i).cord.y > row - 5 and shells_2(i).cord.y < row + 5) then
										red_tmp := (others => '1');
										green_tmp := (others => '0');
										blue_tmp := (others => '0');
									end if;
								end if;
							end loop;

							-- cannon 1
							if (column > cannon_1_pos.x - 10 and column < cannon_1_pos.x + 10 and row > cannon_1_pos.y - 10 and row < cannon_1_pos.y + 10) then
								red_tmp := (others => '0');
								green_tmp := (others => '1');
								blue_tmp := (others => '0');
							end if;

							-- cannon 2
							if (column > cannon_2_pos.x - 10 and column < cannon_2_pos.x + 10 and row > cannon_2_pos.y - 10 and row < cannon_2_pos.y + 10) then
								red_tmp := (others => '0');
								green_tmp := (others => '1');
								blue_tmp := (others => '0');
							end if;

							-- ships 1
							for i in 0 to 4 loop
								if (column >= ships_1(i).pos1.x - 1 and column < ships_1(i).pos1.x + ships_1(i).ship_type.ship_image_width and row >= ships_1(i).pos1.y and row < ships_1(i).pos1.y + ships_1(i).ship_type.ship_image_height) then
									if (ships_1(i).ship_type.id = destroyer_id) then
										ship_memory_offset := 1300;
									elsif (ships_1(i).ship_type.id = battle_ship_id) then
										ship_memory_offset := 2554;
									else
										ship_memory_offset := 0;
									end if;

									ship_array_index := ship_memory_offset + (ships_1(i).ship_type.ship_image_width * ((row - ships_1(i).pos1.y)) + (column - ships_1(i).pos1.x)) + 1;
									if (column /= ships_1(i).pos1.x - 1) then
										if (data(7 downto 0) = x"FF") then
											red_tmp := data(15 downto 8);
											green_tmp := data(15 downto 8);
											blue_tmp := data(15 downto 8);
										end if;
									end if;
								end if;
							end loop;

							-- ships 2
							for i in 0 to 4 loop
								if (column >= ships_2(i).pos1.x - 1 and column < ships_2(i).pos1.x + ships_2(i).ship_type.ship_image_width and row >= ships_2(i).pos1.y and row < ships_2(i).pos1.y + ships_2(i).ship_type.ship_image_height) then
									if (ships_1(i).ship_type.id = destroyer_id) then
										ship_memory_offset := 1300;
									elsif (ships_1(i).ship_type.id = battle_ship_id) then
										ship_memory_offset := 2554;
									else
										ship_memory_offset := 0;
									end if;

									ship_array_index := ship_memory_offset + (ships_2(i).ship_type.ship_image_width * ((row - ships_2(i).pos1.y)) + (column - ships_2(i).pos1.x)) + 1;
									if (column /= ships_2(i).pos1.x - 1) then
										if (data(7 downto 0) = x"FF") then
											red_tmp := data(15 downto 8);
											green_tmp := x"55";
											blue_tmp := data(15 downto 8);
										end if;
									end if;
								end if;
							end loop;
						else
							--right panel
							red_tmp := (others => '1');
							green_tmp := (others => '1');
							blue_tmp := (others => '0');
						end if;
					else
						-- footer
						red_tmp := (others => '1');
						green_tmp := (others => '1');
						blue_tmp := (others => '0');

						for text_i in 0 to 1 loop
							for i in all_texts_play_game_footer(text_i).array_of_letters'range loop
								cur_char := all_texts_play_game_footer(text_i).array_of_letters(i);
								cur_char_font_num := CharToFontPos(cur_char);
								letter_pos := (x => all_texts_play_game_footer(text_i).position.x + (letter_size.x + 1) * i, y => all_texts_play_game_footer(text_i).position.y);
								if (row >= letter_pos.y and column >= letter_pos.x - 1 and row < letter_pos.y + letter_size.y and column < letter_pos.x + letter_size.x) then

									ship_array_index := (font_start_byte + font_row_size_byte * (row - letter_pos.y) + (column - letter_pos.x + letter_size.x * (cur_char_font_num + score_digits_array(text_i)(i))) + 1) / 2;

									if (column /= letter_pos.x - 1) then
										if ((column - letter_pos.x) mod 2 = 0) then
											if (data(15 downto 8) = x"01") then
												red_tmp := x"00";
												green_tmp := x"00";
												blue_tmp := x"00";
											end if;
										else
											if (data(7 downto 0) = x"01") then
												red_tmp := x"00";
												green_tmp := x"00";
												blue_tmp := x"00";
											end if;
										end if;

									end if;
								end if;
							end loop;
						end loop;
					end if;

				elsif (game_state = GAME_END) then
					red_tmp := x"FF";
					green_tmp := x"AA";
					blue_tmp := x"00";

					for text_i in 0 to 2 loop
						for i in all_texts_end_game(text_i).array_of_letters'range loop
							cur_char := all_texts_end_game(text_i).array_of_letters(i);
							cur_char_font_num := CharToFontPos(cur_char);
							letter_pos := (x => all_texts_end_game(text_i).position.x + (letter_size.x + 1) * i, y => all_texts_end_game(text_i).position.y);
							if (row >= letter_pos.y and column >= letter_pos.x - 1 and row < letter_pos.y + letter_size.y and column < letter_pos.x + letter_size.x) then

								ship_array_index := (font_start_byte + font_row_size_byte * (row - letter_pos.y) + (column - letter_pos.x + letter_size.x * (cur_char_font_num)) + 1) / 2;

								if (column /= letter_pos.x - 1) then
									if ((column - letter_pos.x) mod 2 = 0) then
										if (data(15 downto 8) = x"01") then
											red_tmp := x"00";
											green_tmp := x"00";
											blue_tmp := x"00";
										end if;
									else
										if (data(7 downto 0) = x"01") then
											red_tmp := x"00";
											green_tmp := x"00";
											blue_tmp := x"00";
										end if;
									end if;

								end if;
							end if;
						end loop;
					end loop;
				end if;

				sram_addres_read <= std_logic_vector(to_unsigned(ship_array_index, 20));

				--------------------------------------
				--// all letters
				-- if (row < 14) then
				-- 	sram_addres_read <= std_logic_vector(to_unsigned((column + font_start_byte + row * font_row_size_byte)/2, 20));
				-- 	if ((column - letter_pos.x) mod 2 = 0) then
				-- 		if (data(15 downto 8) = x"01") then
				-- 			blue <= x"00";
				-- 			green <= x"00";
				-- 			red <= x"00";
				-- 		elsif (data(15 downto 8) = x"00") then
				-- 			blue <= x"FF";
				-- 			green <= x"FF";
				-- 			red <= x"FF";
				-- 		end if;
				-- 	else
				-- 		if (data(7 downto 0) = x"01") then
				-- 			blue <= x"00";
				-- 			green <= x"00";
				-- 			red <= x"00";
				-- 		elsif (data(7 downto 0) = x"00") then
				-- 			blue <= x"FF";
				-- 			green <= x"FF";
				-- 			red <= x"FF";
				-- 		end if;
				-- 	end if;
				-- end if;
			else
				--blanking time
				red_tmp := x"00";
				green_tmp := x"00";
				blue_tmp := x"00";
			end if;

			blue <= blue_tmp;
			green <= green_tmp;
			red <= red_tmp;

			-- data_count := data_count + 1;
			-- if (ticks > 0) then 
			-- 	ticks := ticks - 1;
			-- else
			-- 	ticks := 40_000_000;

			-- 	-- cur_addr := cur_addr + 1;
			-- 	data_count := 0;
			-- end if;
			-- cur_addr := cur_addr + 1;
			-- sram_addres_read <= std_logic_vector(to_unsigned(cur_addr, 20));
			-- if (data /= prev_data) then 
			--     LED <= std_logic_vector(to_unsigned(data_count, 8));
			-- end if;
			-- prev_data := data;
		end if;
	end process;
end a1;