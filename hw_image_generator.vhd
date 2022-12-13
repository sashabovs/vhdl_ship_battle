library work;
use work.DataStructures.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity hw_image_generator is
	generic (
		-- screen size
		screen_w : integer := 5;
		screen_h : integer := 5
	);
	port (
		-- INPUT
		-- clock
		pixel_clk : in std_logic;
		--display enable ('1' = display time, '0' = blanking time)
		disp_ena : in std_logic; 
		--row pixel coordinate
		row : in integer; 
		--column pixel coordinate
		column : in integer; 

		-- play area borders
		first_border_coord : in Coordinates;
		second_border_coord : in Coordinates;

		-- elements to draw
		cannon_1_pos : in Coordinates;
		cannon_2_pos : in Coordinates;
		shells_1 : in ArrayOfShells;
		shells_2 : in ArrayOfShells;
		ships_1 : in ShipArray;
		ships_2 : in ShipArray;

		-- score
		score_1 : in integer;
		score_2 : in integer;

		-- antwort from sram (2 byte)
		data : in std_logic_vector (15 downto 0);
		-- progress of loading of SDCard
		load_progress : in integer;

		-- in-game timer
		game_time : in integer;
		-- state of the game
		game_state : in GameStates;

		-- OUTPUT
		-- sram addres 
		sram_addres_read : out std_logic_vector(19 downto 0);

		--red magnitude output to DAC
		red : out std_logic_vector(7 downto 0) := (others => '0'); 
		--green magnitude output to DAC
		green : out std_logic_vector(7 downto 0) := (others => '0'); 
		--blue magnitude output to DAC
		blue : out std_logic_vector(7 downto 0) := (others => '0') 
	);
end hw_image_generator;

architecture a1 of hw_image_generator is

	-- offset for time text
	signal time_digits_array : DigitsArray := (others => (others => 0));
	-- offset for score text
	signal score_digits_array : DigitsArray := (others => (others => 0));
begin

	-- make score offset
	process (pixel_clk)
	begin
		if (rising_edge(pixel_clk)) then
			-- score 1, numbers are at position 8-10
			score_digits_array(0)(8) <= score_1 / 100;
			score_digits_array(0)(9) <= (score_1 mod 100) / 10;
			score_digits_array(0)(10) <= score_1 mod 10;

			-- score 2, numbers are at position 8-10
			score_digits_array(1)(8) <= score_2 / 100;
			score_digits_array(1)(9) <= (score_2 mod 100) / 10;
			score_digits_array(1)(10) <= score_2 mod 10;
		end if;
	end process;

	-- make time offset
	process (pixel_clk)
		-- minutes 
		variable mins : integer;
		-- seconds
		variable secs : integer;
	begin
		if (rising_edge(pixel_clk)) then
			-- calc mins and secs from time
			mins := game_time / 60;
			secs := game_time mod 60;

			-- generate offset for time
			time_digits_array(0)(1) <= mins / 10;
			time_digits_array(0)(2) <= mins mod 10;
			-- time_digits_array(3) is ':'
			time_digits_array(0)(4) <= secs / 10;
			time_digits_array(0)(5) <= secs mod 10;
		end if;
	end process;



	process (pixel_clk)
		variable sram_index : integer;

		variable red_tmp : std_logic_vector(7 downto 0) := (others => '0');
		variable green_tmp : std_logic_vector(7 downto 0) := (others => '0');
		variable blue_tmp : std_logic_vector(7 downto 0) := (others => '0');

		variable print_text_result : PrintTextResult;

		-- background colors for texts: RGB
		constant background_color_start : std_logic_vector(23 downto 0) := x"FFFF00";
		constant background_color_play : std_logic_vector(23 downto 0) := x"FFFF00";
		constant background_color_end : std_logic_vector(23 downto 0) := x"FFAA00";
	begin
		if (rising_edge(pixel_clk)) then
			--display time
			if (disp_ena = '1') then 
				if (game_state = GAME_LOAD) then

					-- background color
					red_tmp := (others => '1');
					green_tmp := x"BB";
					blue_tmp := (others => '0');

					-- load line
					if (row >= screen_h/2 and column >= 0 and row < screen_h/2 + 10 and column < load_progress * screen_w/175760) then
						red_tmp := (others => '0');
						green_tmp := (others => '1');
						blue_tmp := (others => '0');
					end if;
				elsif (game_state = GAME_START or game_state = WAIT_FOR_GAME) then
					-- draw text
					-- function returns text or background color
					print_text_result := PrintText(all_texts_start_game, 2, column, row, data, (others => (others => 0)), background_color_start);
					red_tmp := print_text_result.color_vector(23 downto 16);
					green_tmp := print_text_result.color_vector(15 downto 8);
					blue_tmp := print_text_result.color_vector(7 downto 0);

					-- if the point was in the text, then we requesting the next point from sram
					if (print_text_result.memory_data_index /= - 1) then
						sram_index := print_text_result.memory_data_index;
					end if;

		
				elsif (game_state = GAME_PLAY) then
					if (row < first_border_coord.y) then
						-- HEADER
						-- draw text
						print_text_result := PrintText(all_texts_play_game_header, 1, column, row, data, time_digits_array, background_color_play);
						red_tmp := print_text_result.color_vector(23 downto 16);
						green_tmp := print_text_result.color_vector(15 downto 8);
						blue_tmp := print_text_result.color_vector(7 downto 0);

						-- if the point was in the text, then we requesting the next point from sram
						if (print_text_result.memory_data_index /= - 1) then
							sram_index := print_text_result.memory_data_index;
						end if;

					elsif (row < second_border_coord.y) then
						if (column < first_border_coord.x) then
							-- LEFT PANEL
							-- background color
							red_tmp := (others => '1');
							green_tmp := (others => '1');
							blue_tmp := (others => '0');
						elsif (column < second_border_coord.x) then
							-- GAME AREA
							-- background color
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

							-- LEFT HALF
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
									-- since memory returns data with a delay, we request it one pixel ahead (column >= ships_2(i).pos1.x - 1)
									if (column >= ships_2(i).pos1.x - 1 and column < ships_2(i).pos1.x + ships_2(i).ship_type.ship_image_width and row >= ships_2(i).pos1.y and row < ships_2(i).pos1.y + ships_2(i).ship_type.ship_image_height) then
										-- if the point is inside the ship, request the point from memory
										-- we ask for the forward point, so the address needs to be moved forward too  (... + 1)
										sram_index := ships_2(i).ship_type.ship_memory_offset + (ships_2(i).ship_type.ship_image_width * ((row - ships_2(i).pos1.y)) + (column - ships_2(i).pos1.x)) + 1;
										-- we ask for the forward point, so the first pixel will have invalid data 
										if (column /= ships_2(i).pos1.x - 1) then
											-- the first byte is the color, the second is the transparency (FF - not transparent)
											-- ships are black-white
											if (data(7 downto 0) = x"FF") then
												-- blue shade
												red_tmp := data(15 downto 8);
												green_tmp := data(15 downto 8);
												blue_tmp := x"30";
											end if;
										end if;
									end if;
								end loop;

							-- RIGHT HALF
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
									-- since memory returns data with a delay, we request it one pixel ahead (column >= ships_2(i).pos1.x - 1)
									if (column >= ships_1(i).pos1.x - 1 and column < ships_1(i).pos1.x + ships_1(i).ship_type.ship_image_width and row >= ships_1(i).pos1.y and row < ships_1(i).pos1.y + ships_1(i).ship_type.ship_image_height) then
										-- if the point is inside the ship, request the point from memory
										-- we ask for the forward point, so the address needs to be moved forward too  (... + 1)
										sram_index := ships_1(i).ship_type.ship_memory_offset + (ships_1(i).ship_type.ship_image_width * ((row - ships_1(i).pos1.y)) + (column - ships_1(i).pos1.x)) + 1;
										-- we ask for the forward point, so the first pixel will have invalid data 
										if (column /= ships_1(i).pos1.x - 1) then
											-- the first byte is the color, the second is the transparency (FF - not transparent)
											-- ships are black-white
											if (data(7 downto 0) = x"FF") then
												-- red shade
												red_tmp := x"30";
												green_tmp := data(15 downto 8);
												blue_tmp := data(15 downto 8);
											end if;
										end if;
									end if;
								end loop;

							end if;
						else
							-- RIGHT PANEL
							-- background color
							red_tmp := (others => '1');
							green_tmp := (others => '1');
							blue_tmp := (others => '0');
						end if;
					else
						-- FOOTER
						-- draw text
						-- function returns text or background color
						print_text_result := PrintText(all_texts_play_game_footer, 2, column, row, data, score_digits_array, background_color_play);
						red_tmp := print_text_result.color_vector(23 downto 16);
						green_tmp := print_text_result.color_vector(15 downto 8);
						blue_tmp := print_text_result.color_vector(7 downto 0);

						-- if the point was in the text, then we requesting the next point from sram
						if (print_text_result.memory_data_index /= - 1) then
							sram_index := print_text_result.memory_data_index;
						end if;

					end if;

				elsif (game_state = GAME_END) then
					-- background color
					red_tmp := background_color_end(23 downto 16);
					green_tmp := background_color_end(15 downto 8);
					blue_tmp := background_color_end(7 downto 0);

					if (row <= all_texts_end_game_over(0).range_y.start_pos) then

					elsif (row <= all_texts_end_game_over(0).range_y.end_pos) then
						-- text game over
						-- function returns text or background color
						print_text_result := PrintText(all_texts_end_game_over, 1, column, row, data, (others => (others => 0)), background_color_end);
						-- if the point was in the text, then we requesting the next point from sram
						if (print_text_result.memory_data_index /= - 1) then
							-- since we have already set the background color, we will only draw the text
							red_tmp := print_text_result.color_vector(23 downto 16);
							green_tmp := print_text_result.color_vector(15 downto 8);
							blue_tmp := print_text_result.color_vector(7 downto 0);
							sram_index := print_text_result.memory_data_index;
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

						-- if the point was in the text, then we requesting the next point from sram
						if (print_text_result.memory_data_index /= - 1) then
							-- since we have already set the background color, we will only draw the text
							red_tmp := print_text_result.color_vector(23 downto 16);
							green_tmp := print_text_result.color_vector(15 downto 8);
							blue_tmp := print_text_result.color_vector(7 downto 0);
							sram_index := print_text_result.memory_data_index;
						end if;
					else
						-- text game end
						print_text_result := PrintText(all_texts_end_game, 2, column, row, data, (others => (others => 0)), background_color_end);
						-- if the point was in the text, then we requesting the next point from sram
						if (print_text_result.memory_data_index /= - 1) then
							-- since we have already set the background color, we will only draw the text
							red_tmp := print_text_result.color_vector(23 downto 16);
							green_tmp := print_text_result.color_vector(15 downto 8);
							blue_tmp := print_text_result.color_vector(7 downto 0);
							sram_index := print_text_result.memory_data_index;
						end if;
					end if;
				end if;

				-- send out sram addres
				sram_addres_read <= std_logic_vector(to_unsigned(sram_index, 20));

			else
				--blanking time
				red_tmp := x"00";
				green_tmp := x"00";
				blue_tmp := x"00";
			end if;

			-- set color to output signals
			blue <= blue_tmp;
			green <= green_tmp;
			red <= red_tmp;

		end if;
	end process;
end a1;