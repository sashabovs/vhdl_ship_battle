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

		load_progress : in integer;

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

begin

	process (pixel_clk)
	begin
		if (rising_edge(pixel_clk)) then
			score_digits_array(0)(8) <= score_1 / 100;
			score_digits_array(0)(9) <= (score_1 mod 100) / 10;
			score_digits_array(0)(10) <= score_1 mod 10;

			score_digits_array(1)(8) <= score_2 / 100;
			score_digits_array(1)(9) <= (score_2 mod 100) / 10;
			score_digits_array(1)(10) <= score_2 mod 10;
		end if;
	end process;

	process (pixel_clk)
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

		variable letter_pos_left_top : Coordinates;
		variable letter_pos_right_bottom : Coordinates;

		variable ship_memory_offset : integer := 0;

		variable sleep : integer := 0;
		variable letter_num : integer := 0;

		-- variable ticks: integer:= 40_000_000;
		-- variable cur_addr: integer := 100;
		-- variable data_count: integer:= 0;
		-- variable prev_data : std_logic_vector (15 downto 0);

		variable cur_char : character;
		variable cur_char_font_num : integer;
		variable text_num : integer range 0 to 3 := 0;

		variable print_text_result : PrintTextResult;

		-- background colors: RGB
		constant background_color_start : std_logic_vector(23 downto 0) := x"FFFF00";
		constant background_color_play : std_logic_vector(23 downto 0) := x"FFFF00";
		constant background_color_end : std_logic_vector(23 downto 0) := x"FFAA00";
	begin
		if (rising_edge(pixel_clk)) then
			if (disp_ena = '1') then --display time
				if (game_state = GAME_LOAD) then

					red_tmp := (others => '1');
					green_tmp := x"BB";
					blue_tmp := (others => '0');

					if (row >= screen_h/2 and column >= 0 and row < screen_h/2 + 10 and column < load_progress * screen_w/175760) then
						red_tmp := (others => '0');
						green_tmp := (others => '1');
						blue_tmp := (others => '0');
					end if;
				elsif (game_state = GAME_START) then

					-- red_tmp := (others => '1');
					-- green_tmp := (others => '1');
					-- blue_tmp := (others => '0');

					print_text_result := PrintText(all_texts_start_game, 2, column, row, data, (others => (others => 0)), background_color_start);
					red_tmp := print_text_result.color_vector(23 downto 16);
					green_tmp := print_text_result.color_vector(15 downto 8);
					blue_tmp := print_text_result.color_vector(7 downto 0);
					if (print_text_result.memory_data_index /= - 1) then
						ship_array_index := print_text_result.memory_data_index;
					end if;

					-- for text_i in 0 to 1 loop
					-- 	for i in all_texts_start_game(text_i).array_of_letters'range loop
					-- 		--for i in 1 to 4 loop
					-- 		cur_char := all_texts_start_game(text_i).array_of_letters(i);
					-- 		cur_char_font_num := CharToFontPos(cur_char);

					-- 		letter_pos_left_top := (x => all_texts_start_game(text_i).ranges_x(i).start_pos, y => all_texts_start_game(text_i).range_y.start_pos);
					-- 		letter_pos_right_bottom := (x => all_texts_start_game(text_i).ranges_x(i).end_pos, y => all_texts_start_game(text_i).range_y.end_pos);
					-- 		if (row >= letter_pos_left_top.y and column >= letter_pos_left_top.x and row < letter_pos_right_bottom.y and column < letter_pos_right_bottom.x) then

					-- 			ship_array_index := (font_start_byte + font_row_start_pos_y(row - letter_pos_left_top.y) + column - letter_pos_left_top.x + font_letter_start_pos_x(cur_char_font_num)) / 2;
					-- 			if ((column - letter_pos_left_top.x) mod 2 = 0) then
					-- 				if (data(15 downto 8) = x"01") then
					-- 					red_tmp := x"00";
					-- 					green_tmp := x"00";
					-- 					blue_tmp := x"00";
					-- 				end if;
					-- 			else
					-- 				if (data(7 downto 0) = x"01") then
					-- 					red_tmp := x"00";
					-- 					green_tmp := x"00";
					-- 					blue_tmp := x"00";
					-- 				end if;
					-- 			end if;
					-- 		end if;
					-- 	end loop;
					-- end loop;

					-----
					--// all letters
					-- if (row < 28) then
					-- 	ship_array_index := (column/2 + font_start_byte + font_row_start_pos_y(row/2))/2;
					-- 	if ((column/2) mod 2 = 1) then
					-- 		if (data(15 downto 8) = x"01") then
					-- 			blue_tmp := x"00";
					-- 			green_tmp := x"00";
					-- 			red_tmp := x"00";
					-- 		elsif (data(15 downto 8) = x"00") then
					-- 			blue_tmp := x"FF";
					-- 			green_tmp := x"FF";
					-- 			red_tmp := x"FF";
					-- 		end if;
					-- 	else
					-- 		if (data(7 downto 0) = x"01") then
					-- 			blue_tmp := x"00";
					-- 			green_tmp := x"00";
					-- 			red_tmp := x"00";
					-- 		elsif (data(7 downto 0) = x"00") then
					-- 			blue_tmp := x"FF";
					-- 			green_tmp := x"FF";
					-- 			red_tmp := x"FF";
					-- 		end if;
					-- 	end if;
					-- elsif (row < 56) then
					-- 	ship_array_index := (column/2 + 396 + font_start_byte + font_row_start_pos_y((row - 28)/2))/2;
					-- 	if ((column/2) mod 2 = 1) then
					-- 		if (data(15 downto 8) = x"01") then
					-- 			blue_tmp := x"00";
					-- 			green_tmp := x"00";
					-- 			red_tmp := x"00";
					-- 		elsif (data(15 downto 8) = x"00") then
					-- 			blue_tmp := x"FF";
					-- 			green_tmp := x"FF";
					-- 			red_tmp := x"FF";
					-- 		end if;
					-- 	else
					-- 		if (data(7 downto 0) = x"01") then
					-- 			blue_tmp := x"00";
					-- 			green_tmp := x"00";
					-- 			red_tmp := x"00";
					-- 		elsif (data(7 downto 0) = x"00") then
					-- 			blue_tmp := x"FF";
					-- 			green_tmp := x"FF";
					-- 			red_tmp := x"FF";
					-- 		end if;
					-- 	end if;

					-- elsif (row < 84) then
					-- 	ship_array_index := (column/2 + 792 + font_start_byte + font_row_start_pos_y((row - 56)/2))/2;
					-- 	if ((column/2) mod 2 = 1) then
					-- 		if (data(15 downto 8) = x"01") then
					-- 			blue_tmp := x"00";
					-- 			green_tmp := x"00";
					-- 			red_tmp := x"00";
					-- 		elsif (data(15 downto 8) = x"00") then
					-- 			blue_tmp := x"FF";
					-- 			green_tmp := x"FF";
					-- 			red_tmp := x"FF";
					-- 		end if;
					-- 	else
					-- 		if (data(7 downto 0) = x"01") then
					-- 			blue_tmp := x"00";
					-- 			green_tmp := x"00";
					-- 			red_tmp := x"00";
					-- 		elsif (data(7 downto 0) = x"00") then
					-- 			blue_tmp := x"FF";
					-- 			green_tmp := x"FF";
					-- 			red_tmp := x"FF";
					-- 		end if;
					-- 	end if;
					-- end if;
					------------
				elsif (game_state = GAME_PLAY) then
					if (row < first_border_coord.y) then
						-- header
						print_text_result := PrintText(all_texts_play_game_header, 1, column, row, data, time_digits_array, background_color_play);
						red_tmp := print_text_result.color_vector(23 downto 16);
						green_tmp := print_text_result.color_vector(15 downto 8);
						blue_tmp := print_text_result.color_vector(7 downto 0);
						if (print_text_result.memory_data_index /= - 1) then
							ship_array_index := print_text_result.memory_data_index;
						end if;

						-- red_tmp := (others => '1');
						-- green_tmp := (others => '1');
						-- blue_tmp := (others => '0');

						-- for text_i in 0 to 0 loop
						-- 	for i in all_texts_play_game_header(text_i).array_of_letters'range loop
						-- 		cur_char := all_texts_play_game_header(text_i).array_of_letters(i);
						-- 		cur_char_font_num := CharToFontPos(cur_char);

						-- 		letter_pos_left_top := (x => all_texts_play_game_header(text_i).ranges_x(i).start_pos, y => all_texts_play_game_header(text_i).range_y.start_pos);
						-- 		letter_pos_right_bottom := (x => all_texts_play_game_header(text_i).ranges_x(i).end_pos, y => all_texts_play_game_header(text_i).range_y.end_pos);

						-- 		if (row >= letter_pos_left_top.y and column >= letter_pos_left_top.x - 1 and row < letter_pos_right_bottom.y and column < letter_pos_right_bottom.x) then

						-- 			ship_array_index := (font_start_byte + font_row_start_pos_y(row - letter_pos_left_top.y) + (column - letter_pos_left_top.x + font_letter_start_pos_x(cur_char_font_num + time_digits_array(text_i)(i))) + 1) / 2;

						-- 			if (column /= letter_pos_left_top.x - 1) then
						-- 				if ((column - letter_pos_left_top.x) mod 2 = 0) then
						-- 					if (data(15 downto 8) = x"01") then
						-- 						red_tmp := x"00";
						-- 						green_tmp := x"00";
						-- 						blue_tmp := x"00";
						-- 					end if;
						-- 				else
						-- 					if (data(7 downto 0) = x"01") then
						-- 						red_tmp := x"00";
						-- 						green_tmp := x"00";
						-- 						blue_tmp := x"00";
						-- 					end if;
						-- 				end if;

						-- 			end if;
						-- 		end if;
						-- 	end loop;
						-- end loop;
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

							if (column * 2 < screen_w) then
								-- player 1 side
								-- cannon 1
								if (column > cannon_1_pos.x - 10 and column < cannon_1_pos.x + 10 and row > cannon_1_pos.y - 10 and row < cannon_1_pos.y + 10) then
									red_tmp := (others => '0');
									green_tmp := (others => '1');
									blue_tmp := (others => '0');
								end if;

								-- ships 1
								for i in 0 to 4 loop
									if (column >= ships_2(i).pos1.x - 1 and column < ships_2(i).pos1.x + ships_2(i).ship_type.ship_image_width and row >= ships_2(i).pos1.y and row < ships_2(i).pos1.y + ships_2(i).ship_type.ship_image_height) then
										ship_array_index := ships_2(i).ship_type.ship_memory_offset + (ships_2(i).ship_type.ship_image_width * ((row - ships_2(i).pos1.y)) + (column - ships_2(i).pos1.x)) + 1;
										if (column /= ships_2(i).pos1.x - 1) then
											if (data(7 downto 0) = x"FF") then
												red_tmp := data(15 downto 8);
												green_tmp := data(15 downto 8);
												blue_tmp := x"30";
											end if;
										end if;
									end if;
								end loop;

							else
								-- player 2 side
								-- cannon 2
								if (column > cannon_2_pos.x - 10 and column < cannon_2_pos.x + 10 and row > cannon_2_pos.y - 10 and row < cannon_2_pos.y + 10) then
									red_tmp := (others => '0');
									green_tmp := (others => '1');
									blue_tmp := (others => '0');
								end if;

								-- ships 2
								for i in 0 to 4 loop
									if (column >= ships_1(i).pos1.x - 1 and column < ships_1(i).pos1.x + ships_1(i).ship_type.ship_image_width and row >= ships_1(i).pos1.y and row < ships_1(i).pos1.y + ships_1(i).ship_type.ship_image_height) then
										ship_array_index := ships_1(i).ship_type.ship_memory_offset + (ships_1(i).ship_type.ship_image_width * ((row - ships_1(i).pos1.y)) + (column - ships_1(i).pos1.x)) + 1;
										if (column /= ships_1(i).pos1.x - 1) then
											if (data(7 downto 0) = x"FF") then
												red_tmp := data(15 downto 8);
												green_tmp := data(15 downto 8);
												blue_tmp := data(15 downto 8);
											end if;
										end if;
									end if;
								end loop;

							end if;
						else
							--right panel
							red_tmp := (others => '1');
							green_tmp := (others => '1');
							blue_tmp := (others => '0');
						end if;
					else
						-- footer

						print_text_result := PrintText(all_texts_play_game_footer, 2, column, row, data, score_digits_array, background_color_play);
						red_tmp := print_text_result.color_vector(23 downto 16);
						green_tmp := print_text_result.color_vector(15 downto 8);
						blue_tmp := print_text_result.color_vector(7 downto 0);
						if (print_text_result.memory_data_index /= - 1) then
							ship_array_index := print_text_result.memory_data_index;
						end if;

						-- red_tmp := (others => '1');
						-- green_tmp := (others => '1');
						-- blue_tmp := (others => '0');

						-- for text_i in 0 to 1 loop
						-- 	for i in all_texts_play_game_footer(text_i).array_of_letters'range loop
						-- 		cur_char := all_texts_play_game_footer(text_i).array_of_letters(i);
						-- 		cur_char_font_num := CharToFontPos(cur_char);

						-- 		letter_pos_left_top := (x => all_texts_play_game_footer(text_i).ranges_x(i).start_pos, y => all_texts_play_game_footer(text_i).range_y.start_pos);
						-- 		letter_pos_right_bottom := (x => all_texts_play_game_footer(text_i).ranges_x(i).end_pos, y => all_texts_play_game_footer(text_i).range_y.end_pos);

						-- 		if (row >= letter_pos_left_top.y and column >= letter_pos_left_top.x and row < letter_pos_right_bottom.y and column < letter_pos_right_bottom.x) then

						-- 			ship_array_index := (font_start_byte + font_row_start_pos_y(row - letter_pos_left_top.y) + (column - letter_pos_left_top.x + font_letter_start_pos_x(cur_char_font_num + score_digits_array(text_i)(i)))) / 2;

						-- 			--if (column /= letter_pos.x - 1) then
						-- 			if ((column - letter_pos_left_top.x) mod 2 = 0) then
						-- 				if (data(15 downto 8) = x"01") then
						-- 					red_tmp := x"00";
						-- 					green_tmp := x"00";
						-- 					blue_tmp := x"00";
						-- 				end if;
						-- 			else
						-- 				if (data(7 downto 0) = x"01") then
						-- 					red_tmp := x"00";
						-- 					green_tmp := x"00";
						-- 					blue_tmp := x"00";
						-- 				end if;
						-- 			end if;

						-- 			--end if;
						-- 		end if;
						-- 	end loop;
						-- end loop;
					end if;

				elsif (game_state = GAME_END) then
					red_tmp := background_color_end(23 downto 16);
					green_tmp := background_color_end(15 downto 8);
					blue_tmp := background_color_end(7 downto 0);

					if (row <= all_texts_end_game_over(0).range_y.start_pos) then

					elsif (row <= all_texts_end_game_over(0).range_y.end_pos) then
						-- text game over
						print_text_result := PrintText(all_texts_end_game_over, 1, column, row, data, (others => (others => 0)), background_color_end);
						if (print_text_result.memory_data_index /= - 1) then
							red_tmp := print_text_result.color_vector(23 downto 16);
							green_tmp := print_text_result.color_vector(15 downto 8);
							blue_tmp := print_text_result.color_vector(7 downto 0);
							ship_array_index := print_text_result.memory_data_index;
						end if;

					elsif (row <= all_texts_end_game_result_won_1(0).range_y.end_pos) then
						-- text result
						if (score_1 > score_2) then
							print_text_result := PrintText(all_texts_end_game_result_won_1, 1, column, row, data, (others => (others => 0)), background_color_end);
						elsif (score_1 < score_2) then
							print_text_result := PrintText(all_texts_end_game_result_won_2, 1, column, row, data, (others => (others => 0)), background_color_end);
						else
							print_text_result := PrintText(all_texts_end_game_result_draw, 1, column, row, data, (others => (others => 0)), background_color_end);
						end if;

						if (print_text_result.memory_data_index /= - 1) then
							red_tmp := print_text_result.color_vector(23 downto 16);
							green_tmp := print_text_result.color_vector(15 downto 8);
							blue_tmp := print_text_result.color_vector(7 downto 0);
							ship_array_index := print_text_result.memory_data_index;
						end if;
					else
						-- text game end

						print_text_result := PrintText(all_texts_end_game, 2, column, row, data, (others => (others => 0)), background_color_end);
						if (print_text_result.memory_data_index /= - 1) then
							red_tmp := print_text_result.color_vector(23 downto 16);
							green_tmp := print_text_result.color_vector(15 downto 8);
							blue_tmp := print_text_result.color_vector(7 downto 0);
							ship_array_index := print_text_result.memory_data_index;
						end if;
					end if;
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