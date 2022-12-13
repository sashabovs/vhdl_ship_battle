library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sine_package.all;

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
		-- ship type identificator
		id : integer;

		color : std_logic_vector (23 downto 0);
		-- value is added to score after destraction of ship 
		value : integer;

		-- ship size
		ship_image_width : integer;
		ship_image_height : integer;

		-- position of ship in memory
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
	-- we can have text with maximal length of 21
	constant text_string_length : integer range 0 to 21 := 21;
	-- we can have up to 3 texts in one array of texts
	constant text_num : integer range 0 to 3 := 3;

	type array_of_ranges is array(positive range <>) of Boundaries;

	type Text is record
		-- height boundaries
		range_y : Boundaries;
		-- text
		array_of_letters : string(1 to text_string_length);
		-- array of width boundaries of each leter in text
		ranges_x : array_of_ranges(1 to text_string_length);
	end record;

	-- array of texts
	type TextArray is array(0 to text_num - 1) of Text;

	-- offset for text
	type array_of_digits is array(1 to text_string_length) of integer;
	-- array of offsets
	type DigitsArray is array(0 to text_num - 1) of array_of_digits;

	-- creates text object from position and string
	function GetText(
		input_text : string;
		position : Coordinates
	) return Text;

	-- size off each letter
	constant letter_size : Coordinates := (x => 12, y => 14);

	-- possition of font in memory of sram
	constant font_start_byte : integer := 5908;
	-- length of font row in bytes
	constant font_row_size_byte : integer := 2304;

	-- calculation optimization
	-- positions of start of letter in loaded font
	type LetterStartArray is array(0 to 127) of integer;
	function GenerateLetterStart return LetterStartArray;
	-- positions of row start of letter in loaded font
	type LetterFontRowStartArray is array(0 to letter_size.y) of integer;
	function GenerateLetterFontRowStart return LetterFontRowStartArray;

	-- predefined texts
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
		WAIT_FOR_GAME,
		GAME_PLAY,
		GAME_END
	);

	-- rgb in one array 
	subtype ColorVector is std_logic_vector(23 downto 0);

	-- return type off print text function
	type PrintTextResult is record
		-- color of point
		color_vector : ColorVector;
		-- position of point of letter in loaded memory. if point not over the text returns -1 
		memory_data_index : integer;
	end record;

	-- prints text
	function PrintText(
		-- array of texts to print
		all_texts : TextArray;
		-- num of texts from array to print
		text_arr_len : integer range 0 to 2;
		-- position of asked point
		column : integer;
		row : integer;
		-- antwort from memory with color
		data : std_logic_vector(15 downto 0);
		-- digit offset
		time_digits_array : DigitsArray;
		-- background color
		initial_color : ColorVector
	) return PrintTextResult;


	type AudioTypeForFire is record
		-- parameters
		sleep : integer;
		sleep_sec : integer;
		sleep_cur : integer;
		v_tstep : integer;
		quarter_num : std_logic;
		quarter_sign : integer;

		-- result audio
		temp_out : signed(15 downto 0);

		-- 1 when sound is ended, 0 when in progress
		finished : std_logic;
	end record;

	type AudioTypeForExplosion is record
		-- parameters
		sleep : integer;
		sleep_sec : integer;
		sleep_cur : integer;
		v_tstep : integer;
		quarter_num : std_logic;
		quarter_sign : integer;
		stage : integer;
		ampl_mult : integer;
		ampl_div : integer;
		
		-- result audio
		temp_out : signed(15 downto 0);

		-- 1 when sound is ended, 0 when in progress
		finished : std_logic;
	end record;

	function PlayFireSound(
		data_in : AudioTypeForFire
	) return AudioTypeForFire;

	function PlayExplosionSound(
		data_in : AudioTypeForExplosion
	) return AudioTypeForExplosion;

end package DataStructures;

package body DataStructures is


	function GetText(
		input_text : string(1 to text_string_length);
		position : Coordinates
	) return Text is
		variable temp_text : Text;
	begin
		-- set height boundaries
		temp_text.range_y.start_pos := position.y;
		temp_text.range_y.end_pos := position.y + letter_size.y;

		temp_text.array_of_letters := input_text;

		-- set width borders
		for i in input_text'range loop
			-- between the letters gap in 5 pixels (i starts from 1)
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

	-- the loaded font is missing the first 32 char symbols
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
		variable sram_index : integer := - 1;
		variable res : PrintTextResult := (color_vector => initial_color, memory_data_index => - 1);
	begin
		-- for all texts
		for text_i in 0 to text_arr_len - 1 loop
			-- for all letters in text
			for i in all_texts(text_i).array_of_letters'range loop
				-- get char from text
				cur_char := all_texts(text_i).array_of_letters(i);
				-- convert to appropriate form
				cur_char_font_num := CharToFontPos(cur_char);

				-- points of letter
				letter_pos_left_top := (x => all_texts(text_i).ranges_x(i).start_pos, y => all_texts(text_i).range_y.start_pos);
				letter_pos_right_bottom := (x => all_texts(text_i).ranges_x(i).end_pos, y => all_texts(text_i).range_y.end_pos);

				-- if point in letter
				if (row >= letter_pos_left_top.y and column >= letter_pos_left_top.x and row < letter_pos_right_bottom.y and column <= letter_pos_right_bottom.x) then
					-- read it from memory
					-- .... * 2    |data byte|fake byte|
					-- .... / 2    we read 2 bytes from memory, so 1 addres = 2 bytes
					sram_index := (font_start_byte + font_row_start_pos_y(row - letter_pos_left_top.y) + (column - letter_pos_left_top.x + font_letter_start_pos_x(cur_char_font_num + time_digits_array(text_i)(i))) * 2) / 2;

					-- sram has delay. First pixel is invalid
					if (column /= letter_pos_left_top.x) then
						-- point of font in memory is black when x"01"
						if (data(15 downto 8) = x"01") then
							red_tmp := x"00";
							green_tmp := x"00";
							blue_tmp := x"00";
						end if;
					end if;
					res := (color_vector => red_tmp & green_tmp & blue_tmp, memory_data_index => sram_index);
				end if;
			end loop;
		end loop;
		return res;
	end function;


	-- test function prints all loaded font
	function PrintAllLetters(
		column : integer;
		row : integer;
		data : std_logic_vector(15 downto 0);
		initial_color : ColorVector
	) return PrintTextResult is
		variable red_tmp : std_logic_vector(7 downto 0) := initial_color(23 downto 16);
		variable green_tmp : std_logic_vector(7 downto 0) := initial_color(15 downto 8);
		variable blue_tmp : std_logic_vector(7 downto 0) := initial_color(7 downto 0);
		variable sram_index : integer := - 1;
		variable res : PrintTextResult := (color_vector => initial_color, memory_data_index => - 1);
	begin
		if (row < 28) then
			sram_index := (column/2 + font_start_byte + font_row_start_pos_y(row/2))/2;
			if ((column/2) mod 2 = 1) then
				if (data(15 downto 8) = x"01") then
					blue_tmp := x"00";
					green_tmp := x"00";
					red_tmp := x"00";
				end if;
			else
				if (data(7 downto 0) = x"01") then
					blue_tmp := x"00";
					green_tmp := x"00";
					red_tmp := x"00";
				end if;
			end if;
		elsif (row < 56) then
			sram_index := (column/2 + 396 + font_start_byte + font_row_start_pos_y((row - 28)/2))/2;
			if ((column/2) mod 2 = 1) then
				if (data(15 downto 8) = x"01") then
					blue_tmp := x"00";
					green_tmp := x"00";
					red_tmp := x"00";
				end if;
			else
				if (data(7 downto 0) = x"01") then
					blue_tmp := x"00";
					green_tmp := x"00";
					red_tmp := x"00";
				end if;
			end if;

		elsif (row < 84) then
			sram_index := (column/2 + 792 + font_start_byte + font_row_start_pos_y((row - 56)/2))/2;
			if ((column/2) mod 2 = 1) then
				if (data(15 downto 8) = x"01") then
					blue_tmp := x"00";
					green_tmp := x"00";
					red_tmp := x"00";
				end if;
			else
				if (data(7 downto 0) = x"01") then
					blue_tmp := x"00";
					green_tmp := x"00";
					red_tmp := x"00";
				end if;
			end if;
		end if;
		return res;
	end function;
	
	-- play audio
	function PlayFireSound(
		data_in : AudioTypeForFire
	) return AudioTypeForFire is
		variable data : AudioTypeForFire;
	begin
		data := data_in;

		if (data.sleep_sec > 0) then
			data.sleep_sec := data.sleep_sec - 1;
		else
			data.sleep_sec := 50_000;
			data.sleep := data.sleep + 10;
			if (data.sleep > 800) then
				data.sleep := 100;
				-- finish---
				data.finished := '1';
			end if;

		end if;

		if (data.sleep_cur > 0) then
			data.sleep_cur := data.sleep_cur - 1;

		else
			data.sleep_cur := data.sleep;

			if (data.quarter_num = '0') then

				data.temp_out := to_signed(data.quarter_sign * get_table_value(data.v_tstep) * 256, 16);

			else
				data.temp_out := to_signed(data.quarter_sign * get_table_value(max_table_index - data.v_tstep) * 256, 16);

			end if;

			data.v_tstep := data.v_tstep + 1;
			if (data.v_tstep >= 128) then
				data.v_tstep := 0;
				data.quarter_num := not data.quarter_num;
				if (data.quarter_num = '1') then
					data.quarter_sign := - data.quarter_sign;
				end if;
			end if;

		end if;

		return data;
	end function;

	function PlayExplosionSound(
		data_in : AudioTypeForExplosion
	) return AudioTypeForExplosion is
		variable data : AudioTypeForExplosion;
	begin
		data := data_in;
		if (data.sleep_sec > 0) then
			data.sleep_sec := data.sleep_sec - 1;
		else

			if (data.stage = 0) then
				data.sleep_sec := 50_000;
				data.sleep := data.sleep + 10;
				data.ampl_mult := 10;
				data.ampl_div := 1;

				if (data.sleep > 1100) then
					data.stage := 1;
				end if;

			elsif (data.stage = 1) then
				data.sleep_sec := 50_000;
				data.sleep := data.sleep - 10;
				data.ampl_mult := 4;
				data.ampl_div := 1;

				if (data.sleep < 700) then
					data.stage := 2;
				end if;

			elsif (data.stage = 2) then
				data.sleep_sec := 50_000;
				data.sleep := data.sleep + 10;
				data.ampl_mult := 8;
				data.ampl_div := 1;

				if (data.sleep > 900) then
					data.stage := 3;
				end if;

			elsif (data.stage = 3) then
				data.sleep_sec := 50_000;
				data.sleep := data.sleep - 10;
				data.ampl_mult := 6;
				data.ampl_div := 1;

				if (data.sleep < 600) then
					data.stage := 4;
				end if;

			elsif (data.stage = 4) then
				data.sleep_sec := 50_000;
				data.sleep := data.sleep + 10;
				data.ampl_mult := 3;
				data.ampl_div := 1;

				if (data.sleep > 2100) then
					data.stage := 5;
				end if;

			else
				----stop-----
				data.sleep := 100;
				data.finished := '1';
				data.stage := 0;
			end if;
		end if;

		if (data.sleep_cur > 0) then
			data.sleep_cur := data.sleep_cur - 1;

		else
			data.sleep_cur := data.sleep;

			if (data.quarter_num = '0') then

				data.temp_out := to_signed(data.quarter_sign * 2560 * data.ampl_mult / data.ampl_div, 16);

			else
				data.temp_out := to_signed(data.quarter_sign * 2560 * data.ampl_mult / data.ampl_div, 16);

			end if;
			data.v_tstep := data.v_tstep + 1;
			if (data.v_tstep >= 128) then
				data.v_tstep := 0;
				data.quarter_num := not data.quarter_num;
				if (data.quarter_num = '1') then
					data.quarter_sign := - data.quarter_sign;
				end if;
			end if;

		end if;

		return data;
	end function;

end package body DataStructures;