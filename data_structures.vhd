library ieee;
use ieee.std_logic_1164.all;

package DataStructures is
	type Coordinates is record
		x : integer;
		y : integer;
	end record;

	type Boundaries is record
		start_pos : integer;
		end_pos : integer;
	end record;

	type ShellObject is record
		cord : Coordinates;
		enabled : std_logic;
	end record;
	type ArrayOfShells is array(0 to 9) of ShellObject;

	type ShipType is record
		id : integer;

		color : std_logic_vector (23 downto 0);
		value : integer;

		ship_image_width : integer;
		ship_image_height : integer;

		ship_memory_offset : integer;
	end record;

	type ShipObject is record
		pos1 : Coordinates;
		ship_type : ShipType;
	end record;

	type ShipArray is array(0 to 4) of ShipObject;

	constant destroyer_id : integer := 1; --(value: 1)
	constant battle_ship_id : integer := 2; --(value: 5)
	constant civil_ship_id : integer := 3; --(value: -2)

	constant destroyer : ShipType := (
		id => destroyer_id,
		color => "011111000000000000011111",
		value => 1,
		ship_image_width => 11,
		ship_image_height => 114,
		ship_memory_offset => 1300
	);
	constant battleShip : ShipType := (
		id => battle_ship_id,
		color => "000000011111000000011111",
		value => 5,
		ship_image_width => 10,
		ship_image_height => 40,
		ship_memory_offset => 2554
	);
	constant civilShip : ShipType := (
		id => civil_ship_id,
		color => "000000000000001111111111",
		value => - 2,
		ship_image_width => 20,
		ship_image_height => 65,
		ship_memory_offset => 0
	);

	-- letters
	constant text_string_length : integer range 0 to 21 := 21;
	constant text_num : integer range 0 to 3 := 3;

	-- type Letter is record
	-- 	letter_num : integer;
	-- end record;

	type array_of_ranges is array(positive range <>) of Boundaries;

	type Text is record
		range_y : Boundaries;
		array_of_letters : string(1 to text_string_length);
		ranges_x : array_of_ranges(1 to text_string_length);
	end record;

	type array_of_digits is array(1 to text_string_length) of integer;
	type DigitsArray is array(0 to text_num - 1) of array_of_digits;

	type TextArray is array(0 to text_num - 1) of Text;

	function GetText(
		input_text : string;
		position : Coordinates
	) return Text;

	constant letter_size : Coordinates := (x => 12, y => 14);

	constant font_start_byte : integer := 5908;
	constant font_row_size_byte : integer := 2304;

	type LetterStartArray is array(0 to 127) of integer;
	function GenerateLetterStart return LetterStartArray;
	type LetterFontRowStartArray is array(0 to letter_size.y) of integer;
	function GenerateLetterFontRowStart return LetterFontRowStartArray;

	constant all_texts_start_game : TextArray;
	constant all_texts_play_game_header : TextArray;
	constant all_texts_play_game_footer : TextArray;
	constant all_texts_end_game_over : TextArray;
	constant all_texts_end_game : TextArray;
	constant all_texts_end_game_result_won_1 : TextArray;
	constant all_texts_end_game_result_won_2 : TextArray;
	constant all_texts_end_game_result_draw : TextArray;
	constant font_letter_start_pos_x : LetterStartArray;
	constant font_row_start_pos_y : LetterFontRowStartArray;
	---------------------
	type GameStates is (
		GAME_LOAD,
		GAME_START,
		GAME_PLAY,
		GAME_END
	);
	subtype ColorVector is std_logic_vector(23 downto 0);

	type PrintTextResult is record
		color_vector : ColorVector;
		memory_data_index : integer;
	end record;

	function PrintText(
		all_texts : TextArray;
		text_arr_len : integer range 0 to 2;
		column : integer;
		row : integer;
		data : std_logic_vector(15 downto 0);
		time_digits_array : DigitsArray;
		initial_color : ColorVector
	) return PrintTextResult;

end package DataStructures;

package body DataStructures is
	function GetText(
		input_text : string(1 to text_string_length);
		position : Coordinates
	) return Text is
		variable temp_text : Text;
	begin
		temp_text.range_y.start_pos := position.y;
		temp_text.range_y.end_pos := position.y + letter_size.y;

		temp_text.array_of_letters := input_text;

		for i in input_text'range loop
			temp_text.ranges_x(i).start_pos := position.x + (i - 1) * (letter_size.x + 5);
			temp_text.ranges_x(i).end_pos := position.x + (i - 1) * (letter_size.x + 5) + letter_size.x;
		end loop;

		return temp_text;
	end function;

	function GenerateLetterStart return LetterStartArray is
		variable tmp_font_letter_start_pos_x : LetterStartArray;
	begin
		for i in 0 to 127 loop
			tmp_font_letter_start_pos_x(i) := letter_size.x * i;
		end loop;

		return tmp_font_letter_start_pos_x;
	end function;

	function GenerateLetterFontRowStart return LetterFontRowStartArray is
		variable tmp_font_row_start_pos_y : LetterFontRowStartArray;
	begin
		for i in 0 to letter_size.y loop
			tmp_font_row_start_pos_y(i) := font_row_size_byte * i;
		end loop;

		return tmp_font_row_start_pos_y;
	end function;

	constant all_texts_start_game : TextArray := (
		0 => GetText("Start Game           ", (x => 290, y => 260)),
		1 => GetText("Press 'KEY0' to start", (x => 200, y => 290)),
		2 => GetText("                     ", (x => 0, y => 0))
	);

	constant all_texts_play_game_header : TextArray := (
		0 => GetText("00:00                ", (x => 350, y => 10)),
		1 => GetText("                     ", (x => 0, y => 0)),
		2 => GetText("                     ", (x => 0, y => 0))
	);

	constant all_texts_play_game_footer : TextArray := (
		0 => GetText("Score: 000           ", (x => 100, y => 560)),
		1 => GetText("Score: 000           ", (x => 600, y => 560)),
		2 => GetText("                     ", (x => 0, y => 0))
	);

	constant all_texts_end_game_over : TextArray := (
		0 => GetText("Game over            ", (x => 300, y => 260)),
		1 => GetText("                     ", (x => 0, y => 0)),
		2 => GetText("                     ", (x => 0, y => 0))
	);

	constant all_texts_end_game : TextArray := (
		0 => GetText("Press 'KEY0' to play ", (x => 250, y => 520)),
		1 => GetText("Press 'KEY1' to reset", (x => 250, y => 550)),
		2 => GetText("                     ", (x => 0, y => 0))
	);

	constant all_texts_end_game_result_won_1 : TextArray := (
		0 => GetText("Player 1 won         ", (x => 280, y => 290)),
		1 => GetText("                     ", (x => 0, y => 0)),
		2 => GetText("                     ", (x => 0, y => 0))
	);
	constant all_texts_end_game_result_won_2 : TextArray := (
		0 => GetText("Player 2 won         ", (x => 280, y => 290)),
		1 => GetText("                     ", (x => 0, y => 0)),
		2 => GetText("                     ", (x => 0, y => 0))
	);
	constant all_texts_end_game_result_draw : TextArray := (
		0 => GetText("Draw                 ", (x => 320, y => 290)),
		1 => GetText("                     ", (x => 0, y => 0)),
		2 => GetText("                     ", (x => 0, y => 0))
	);

	constant font_letter_start_pos_x : LetterStartArray := GenerateLetterStart;
	constant font_row_start_pos_y : LetterFontRowStartArray := GenerateLetterFontRowStart;

	function CharToFontPos(
		cur_char : character
	) return integer is
	begin
		return character'pos(cur_char) - 32;
	end function;

	function PrintText(
		all_texts : TextArray;
		text_arr_len : integer range 0 to 3;
		column : integer;
		row : integer;
		data : std_logic_vector(15 downto 0);
		time_digits_array : DigitsArray;
		initial_color : ColorVector
	) return PrintTextResult is
		variable cur_char : character;
		variable cur_char_font_num : integer;
		variable red_tmp : std_logic_vector(7 downto 0) := initial_color(23 downto 16);
		variable green_tmp : std_logic_vector(7 downto 0) := initial_color(15 downto 8);
		variable blue_tmp : std_logic_vector(7 downto 0) := initial_color(7 downto 0);
		variable letter_pos_left_top : Coordinates;
		variable letter_pos_right_bottom : Coordinates;
		variable ship_array_index : integer := - 1;
		variable res : PrintTextResult := (color_vector => initial_color, memory_data_index => - 1);
	begin
		for text_i in 0 to text_arr_len - 1 loop
			for i in all_texts(text_i).array_of_letters'range loop
				--for i in 1 to 4 loop
				cur_char := all_texts(text_i).array_of_letters(i);
				cur_char_font_num := CharToFontPos(cur_char);

				letter_pos_left_top := (x => all_texts(text_i).ranges_x(i).start_pos, y => all_texts(text_i).range_y.start_pos);
				letter_pos_right_bottom := (x => all_texts(text_i).ranges_x(i).end_pos, y => all_texts(text_i).range_y.end_pos);
				if (row >= letter_pos_left_top.y and column >= letter_pos_left_top.x and row < letter_pos_right_bottom.y and column <= letter_pos_right_bottom.x) then
					ship_array_index := (font_start_byte + font_row_start_pos_y(row - letter_pos_left_top.y) + (column - letter_pos_left_top.x + font_letter_start_pos_x(cur_char_font_num + time_digits_array(text_i)(i)))*2) / 2;

					if (column /= letter_pos_left_top.x) then
						--if ((column - letter_pos_left_top.x) mod 2 = 0) then
							if (data(15 downto 8) = x"01") then
								red_tmp := x"00";
								green_tmp := x"00";
								blue_tmp := x"00";
							end if;
						--lse
							-- if (data(7 downto 0) = x"01") then
							-- 	red_tmp := x"00";
							-- 	green_tmp := x"00";
							-- 	blue_tmp := x"00";
							-- end if;
						--end if;
					end if;
					res := (color_vector => red_tmp & green_tmp & blue_tmp, memory_data_index => ship_array_index);
				end if;
			end loop;
		end loop;
		return res;
	end function;
	function PrintAllLetters(
		column : integer;
		row : integer;
		data : std_logic_vector(15 downto 0);
		initial_color : ColorVector
	) return PrintTextResult is
		variable red_tmp : std_logic_vector(7 downto 0) := initial_color(23 downto 16);
		variable green_tmp : std_logic_vector(7 downto 0) := initial_color(15 downto 8);
		variable blue_tmp : std_logic_vector(7 downto 0) := initial_color(7 downto 0);
		variable ship_array_index : integer := - 1;
		variable res : PrintTextResult := (color_vector => initial_color, memory_data_index => - 1);
	begin
		if (row < 28) then
			ship_array_index := (column/2 + font_start_byte + font_row_start_pos_y(row/2))/2;
			if ((column/2) mod 2 = 1) then
				if (data(15 downto 8) = x"01") then
					blue_tmp := x"00";
					green_tmp := x"00";
					red_tmp := x"00";
					-- elsif (data(15 downto 8) = x"00") then
					-- 	blue_tmp := x"FF";
					-- 	green_tmp := x"FF";
					-- 	red_tmp := x"FF";
				end if;
			else
				if (data(7 downto 0) = x"01") then
					blue_tmp := x"00";
					green_tmp := x"00";
					red_tmp := x"00";
					-- elsif (data(7 downto 0) = x"00") then
					-- 	blue_tmp := x"FF";
					-- 	green_tmp := x"FF";
					-- 	red_tmp := x"FF";
				end if;
			end if;
		elsif (row < 56) then
			ship_array_index := (column/2 + 396 + font_start_byte + font_row_start_pos_y((row - 28)/2))/2;
			if ((column/2) mod 2 = 1) then
				if (data(15 downto 8) = x"01") then
					blue_tmp := x"00";
					green_tmp := x"00";
					red_tmp := x"00";
					-- elsif (data(15 downto 8) = x"00") then
					-- 	blue_tmp := x"FF";
					-- 	green_tmp := x"FF";
					-- 	red_tmp := x"FF";
				end if;
			else
				if (data(7 downto 0) = x"01") then
					blue_tmp := x"00";
					green_tmp := x"00";
					red_tmp := x"00";
					-- elsif (data(7 downto 0) = x"00") then
					-- 	blue_tmp := x"FF";
					-- 	green_tmp := x"FF";
					-- 	red_tmp := x"FF";
				end if;
			end if;

		elsif (row < 84) then
			ship_array_index := (column/2 + 792 + font_start_byte + font_row_start_pos_y((row - 56)/2))/2;
			if ((column/2) mod 2 = 1) then
				if (data(15 downto 8) = x"01") then
					blue_tmp := x"00";
					green_tmp := x"00";
					red_tmp := x"00";
					-- elsif (data(15 downto 8) = x"00") then
					-- 	blue_tmp := x"FF";
					-- 	green_tmp := x"FF";
					-- 	red_tmp := x"FF";
				end if;
			else
				if (data(7 downto 0) = x"01") then
					blue_tmp := x"00";
					green_tmp := x"00";
					red_tmp := x"00";
					-- elsif (data(7 downto 0) = x"00") then
					-- 	blue_tmp := x"FF";
					-- 	green_tmp := x"FF";
					-- 	red_tmp := x"FF";
				end if;
			end if;
		end if;
		return res;
	end function;

end package body DataStructures;